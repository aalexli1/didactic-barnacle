const router = require('express').Router();
const { body, validationResult } = require('express-validator');
const bcrypt = require('bcryptjs');
const { User, Treasure, Discovery } = require('../models');
const auth = require('../middleware/auth');

const handleValidationErrors = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }
  next();
};

/**
 * @swagger
 * /api/users/profile:
 *   get:
 *     summary: Get user profile
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 */
router.get('/profile', auth, async (req, res) => {
  try {
    const user = await User.findByPk(req.user.id, {
      attributes: { exclude: ['password'] },
      include: [
        {
          model: Treasure,
          as: 'createdTreasures',
          where: { is_active: true },
          required: false,
          limit: 10,
          order: [['created_at', 'DESC']]
        },
        {
          model: Treasure,
          as: 'discoveredTreasures',
          through: {
            attributes: ['discovered_at', 'points_earned']
          },
          required: false,
          limit: 10
        }
      ]
    });

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json(user);
  } catch (error) {
    console.error('Error fetching profile:', error);
    res.status(500).json({ error: 'Failed to fetch profile' });
  }
});

/**
 * @swagger
 * /api/users/profile:
 *   put:
 *     summary: Update user profile
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 */
router.put('/profile',
  auth,
  [
    body('username').optional().isLength({ min: 3, max: 30 }).trim(),
    body('bio').optional().isLength({ max: 500 }),
    body('avatar').optional().isURL()
  ],
  handleValidationErrors,
  async (req, res) => {
    try {
      const user = await User.findByPk(req.user.id);

      if (!user) {
        return res.status(404).json({ error: 'User not found' });
      }

      if (req.body.username && req.body.username !== user.username) {
        const existingUser = await User.findOne({
          where: { username: req.body.username }
        });
        
        if (existingUser) {
          return res.status(400).json({ error: 'Username already taken' });
        }
      }

      await user.update(req.body);

      res.json({
        id: user.id,
        username: user.username,
        email: user.email,
        avatar: user.avatar,
        bio: user.bio
      });
    } catch (error) {
      console.error('Error updating profile:', error);
      res.status(500).json({ error: 'Failed to update profile' });
    }
  }
);

/**
 * @swagger
 * /api/users/friends:
 *   get:
 *     summary: Get friends list
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 */
router.get('/friends', auth, async (req, res) => {
  try {
    const user = await User.findByPk(req.user.id, {
      include: [
        {
          model: User,
          as: 'friends',
          attributes: ['id', 'username', 'avatar', 'points'],
          through: {
            where: { status: 'accepted' },
            attributes: ['accepted_at']
          }
        }
      ]
    });

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json(user.friends || []);
  } catch (error) {
    console.error('Error fetching friends:', error);
    res.status(500).json({ error: 'Failed to fetch friends' });
  }
});

/**
 * @swagger
 * /api/users/leaderboard:
 *   get:
 *     summary: Get leaderboard
 *     tags: [Users]
 */
router.get('/leaderboard', async (req, res) => {
  try {
    const { limit = 50, offset = 0, type = 'points' } = req.query;

    const orderBy = type === 'treasures_found' 
      ? 'treasures_found' 
      : type === 'treasures_created' 
      ? 'treasures_created' 
      : 'points';

    const users = await User.findAll({
      attributes: ['id', 'username', 'avatar', 'points', 'treasures_found', 'treasures_created'],
      where: { is_active: true },
      order: [[orderBy, 'DESC']],
      limit: parseInt(limit),
      offset: parseInt(offset)
    });

    res.json(users);
  } catch (error) {
    console.error('Error fetching leaderboard:', error);
    res.status(500).json({ error: 'Failed to fetch leaderboard' });
  }
});

/**
 * @swagger
 * /api/users/stats:
 *   get:
 *     summary: Get user statistics
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 */
router.get('/stats', auth, async (req, res) => {
  try {
    const userId = req.user.id;

    const [user, recentDiscoveries, treasureStats] = await Promise.all([
      User.findByPk(userId, {
        attributes: ['treasures_created', 'treasures_found', 'points']
      }),
      Discovery.findAll({
        where: { user_id: userId },
        order: [['discovered_at', 'DESC']],
        limit: 5,
        include: [{
          model: Treasure,
          attributes: ['title', 'difficulty']
        }]
      }),
      Treasure.findOne({
        where: { creator_id: userId },
        attributes: [
          [require('sequelize').fn('COUNT', require('sequelize').col('id')), 'total_created'],
          [require('sequelize').fn('SUM', require('sequelize').literal(
            'CASE WHEN is_active = true THEN 1 ELSE 0 END'
          )), 'active_treasures']
        ],
        raw: true
      })
    ]);

    res.json({
      user,
      recentDiscoveries,
      treasureStats
    });
  } catch (error) {
    console.error('Error fetching stats:', error);
    res.status(500).json({ error: 'Failed to fetch statistics' });
  }
});

module.exports = router;