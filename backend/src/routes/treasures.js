const router = require('express').Router();
const { body, query, param, validationResult } = require('express-validator');
const { Op } = require('sequelize');
const { Treasure, User, Discovery, sequelize } = require('../models');
const auth = require('../middleware/auth');
const { redisClient } = require('../config/redis');

const handleValidationErrors = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }
  next();
};

/**
 * @swagger
 * /api/treasures:
 *   post:
 *     summary: Create a new treasure
 *     tags: [Treasures]
 *     security:
 *       - bearerAuth: []
 */
router.post('/',
  auth,
  [
    body('title').notEmpty().trim(),
    body('latitude').isFloat({ min: -90, max: 90 }),
    body('longitude').isFloat({ min: -180, max: 180 }),
    body('visibility').optional().isIn(['public', 'friends', 'private']),
    body('difficulty').optional().isIn(['easy', 'medium', 'hard'])
  ],
  handleValidationErrors,
  async (req, res) => {
    try {
      const treasure = await Treasure.create({
        ...req.body,
        creator_id: req.user.id
      });

      await User.increment('treasures_created', {
        where: { id: req.user.id }
      });

      await redisClient.del('treasures:nearby:*');

      res.status(201).json(treasure);
    } catch (error) {
      console.error('Error creating treasure:', error);
      res.status(500).json({ error: 'Failed to create treasure' });
    }
  }
);

/**
 * @swagger
 * /api/treasures/nearby:
 *   get:
 *     summary: Get treasures within radius
 *     tags: [Treasures]
 *     security:
 *       - bearerAuth: []
 */
router.get('/nearby',
  auth,
  [
    query('latitude').isFloat({ min: -90, max: 90 }),
    query('longitude').isFloat({ min: -180, max: 180 }),
    query('radius').optional().isFloat({ min: 0, max: 50000 }).default(5000)
  ],
  handleValidationErrors,
  async (req, res) => {
    try {
      const { latitude, longitude, radius = 5000 } = req.query;
      const cacheKey = `treasures:nearby:${latitude}:${longitude}:${radius}`;
      
      const cached = await redisClient.get(cacheKey);
      if (cached) {
        return res.json(JSON.parse(cached));
      }

      const point = sequelize.literal(
        `ST_SetSRID(ST_MakePoint(${longitude}, ${latitude}), 4326)`
      );

      const treasures = await Treasure.findAll({
        where: {
          is_active: true,
          [Op.and]: [
            sequelize.where(
              sequelize.fn('ST_DWithin', 
                sequelize.col('location'),
                point,
                radius
              ),
              true
            ),
            {
              [Op.or]: [
                { visibility: 'public' },
                { creator_id: req.user.id },
                {
                  visibility: 'friends',
                  creator_id: {
                    [Op.in]: sequelize.literal(
                      `(SELECT friend_id FROM friends WHERE user_id = '${req.user.id}' AND status = 'accepted')`
                    )
                  }
                }
              ]
            }
          ]
        },
        include: [
          {
            model: User,
            as: 'creator',
            attributes: ['id', 'username', 'avatar']
          }
        ],
        attributes: {
          include: [
            [
              sequelize.fn('ST_Distance',
                sequelize.col('location'),
                point
              ),
              'distance'
            ]
          ]
        },
        order: [[sequelize.literal('distance'), 'ASC']],
        limit: 50
      });

      await redisClient.setEx(cacheKey, 300, JSON.stringify(treasures));

      res.json(treasures);
    } catch (error) {
      console.error('Error fetching nearby treasures:', error);
      res.status(500).json({ error: 'Failed to fetch nearby treasures' });
    }
  }
);

/**
 * @swagger
 * /api/treasures/{id}:
 *   get:
 *     summary: Get specific treasure
 *     tags: [Treasures]
 */
router.get('/:id',
  auth,
  [param('id').isUUID()],
  handleValidationErrors,
  async (req, res) => {
    try {
      const treasure = await Treasure.findByPk(req.params.id, {
        include: [
          {
            model: User,
            as: 'creator',
            attributes: ['id', 'username', 'avatar']
          },
          {
            model: User,
            as: 'discoverers',
            attributes: ['id', 'username'],
            through: {
              attributes: ['discovered_at', 'points_earned']
            }
          }
        ]
      });

      if (!treasure) {
        return res.status(404).json({ error: 'Treasure not found' });
      }

      const canView = treasure.visibility === 'public' ||
        treasure.creator_id === req.user.id ||
        (treasure.visibility === 'friends' && await isFriend(treasure.creator_id, req.user.id));

      if (!canView) {
        return res.status(403).json({ error: 'Access denied' });
      }

      res.json(treasure);
    } catch (error) {
      console.error('Error fetching treasure:', error);
      res.status(500).json({ error: 'Failed to fetch treasure' });
    }
  }
);

/**
 * @swagger
 * /api/treasures/{id}/found:
 *   put:
 *     summary: Mark treasure as found
 *     tags: [Treasures]
 */
router.put('/:id/found',
  auth,
  [
    param('id').isUUID(),
    body('latitude').optional().isFloat({ min: -90, max: 90 }),
    body('longitude').optional().isFloat({ min: -180, max: 180 })
  ],
  handleValidationErrors,
  async (req, res) => {
    const transaction = await sequelize.transaction();
    
    try {
      const treasure = await Treasure.findByPk(req.params.id);
      
      if (!treasure || !treasure.is_active) {
        await transaction.rollback();
        return res.status(404).json({ error: 'Treasure not found or inactive' });
      }

      const existingDiscovery = await Discovery.findOne({
        where: {
          treasure_id: treasure.id,
          user_id: req.user.id
        }
      });

      if (existingDiscovery) {
        await transaction.rollback();
        return res.status(400).json({ error: 'Treasure already discovered' });
      }

      let distance = null;
      if (req.body.latitude && req.body.longitude) {
        const result = await sequelize.query(
          `SELECT ST_Distance(
            location,
            ST_SetSRID(ST_MakePoint(:lon, :lat), 4326)
          ) as distance FROM treasures WHERE id = :id`,
          {
            replacements: {
              lat: req.body.latitude,
              lon: req.body.longitude,
              id: treasure.id
            },
            type: sequelize.QueryTypes.SELECT
          }
        );
        distance = result[0]?.distance;
      }

      const discovery = await Discovery.create({
        treasure_id: treasure.id,
        user_id: req.user.id,
        points_earned: treasure.points,
        distance_from_treasure: distance,
        time_to_find: Math.floor((Date.now() - new Date(treasure.created_at)) / 1000)
      }, { transaction });

      await User.increment(
        { treasures_found: 1, points: treasure.points },
        { where: { id: req.user.id }, transaction }
      );

      const discoveriesCount = await Discovery.count({
        where: { treasure_id: treasure.id }
      });

      if (treasure.max_discoveries && discoveriesCount >= treasure.max_discoveries) {
        await treasure.update({ is_active: false }, { transaction });
      }

      await transaction.commit();

      res.json({
        success: true,
        discovery,
        points_earned: treasure.points
      });
    } catch (error) {
      await transaction.rollback();
      console.error('Error marking treasure as found:', error);
      res.status(500).json({ error: 'Failed to mark treasure as found' });
    }
  }
);

/**
 * @swagger
 * /api/treasures/{id}:
 *   delete:
 *     summary: Delete treasure
 *     tags: [Treasures]
 */
router.delete('/:id',
  auth,
  [param('id').isUUID()],
  handleValidationErrors,
  async (req, res) => {
    try {
      const treasure = await Treasure.findByPk(req.params.id);
      
      if (!treasure) {
        return res.status(404).json({ error: 'Treasure not found' });
      }

      if (treasure.creator_id !== req.user.id) {
        return res.status(403).json({ error: 'Access denied' });
      }

      await treasure.update({ is_active: false });
      
      await redisClient.del('treasures:nearby:*');

      res.json({ success: true });
    } catch (error) {
      console.error('Error deleting treasure:', error);
      res.status(500).json({ error: 'Failed to delete treasure' });
    }
  }
);

async function isFriend(userId, friendId) {
  const { Friend } = require('../models');
  const friendship = await Friend.findOne({
    where: {
      [Op.or]: [
        { user_id: userId, friend_id: friendId },
        { user_id: friendId, friend_id: userId }
      ],
      status: 'accepted'
    }
  });
  return !!friendship;
}

module.exports = router;