const router = require('express').Router();
const { Op } = require('sequelize');
const { User, Treasure, Discovery, Friend, sequelize } = require('../models');
const auth = require('../middleware/auth');
const { redisClient } = require('../config/redis');

/**
 * @swagger
 * /api/activity/feed:
 *   get:
 *     summary: Get activity feed
 *     tags: [Activity]
 *     security:
 *       - bearerAuth: []
 */
router.get('/feed', auth, async (req, res) => {
  try {
    const { limit = 20, offset = 0 } = req.query;
    const userId = req.user.id;
    const cacheKey = `activity:feed:${userId}:${offset}:${limit}`;

    const cached = await redisClient.get(cacheKey);
    if (cached) {
      return res.json(JSON.parse(cached));
    }

    const friendIds = await Friend.findAll({
      where: {
        [Op.or]: [
          { user_id: userId, status: 'accepted' },
          { friend_id: userId, status: 'accepted' }
        ]
      },
      attributes: [],
      raw: true
    }).then(friends => {
      return friends.map(f => f.user_id === userId ? f.friend_id : f.user_id);
    });

    const relevantUserIds = [userId, ...friendIds];

    const [discoveries, treasures] = await Promise.all([
      Discovery.findAll({
        where: {
          user_id: { [Op.in]: relevantUserIds }
        },
        include: [
          {
            model: User,
            attributes: ['id', 'username', 'avatar']
          },
          {
            model: Treasure,
            attributes: ['id', 'title', 'difficulty', 'points'],
            include: [{
              model: User,
              as: 'creator',
              attributes: ['id', 'username']
            }]
          }
        ],
        order: [['discovered_at', 'DESC']],
        limit: parseInt(limit),
        offset: parseInt(offset)
      }),
      Treasure.findAll({
        where: {
          creator_id: { [Op.in]: relevantUserIds },
          is_active: true,
          visibility: { [Op.in]: ['public', 'friends'] }
        },
        include: [{
          model: User,
          as: 'creator',
          attributes: ['id', 'username', 'avatar']
        }],
        order: [['created_at', 'DESC']],
        limit: parseInt(limit),
        offset: parseInt(offset)
      })
    ]);

    const activities = [];

    discoveries.forEach(discovery => {
      activities.push({
        type: 'discovery',
        timestamp: discovery.discovered_at,
        user: discovery.User,
        data: {
          treasure: discovery.Treasure,
          points_earned: discovery.points_earned
        }
      });
    });

    treasures.forEach(treasure => {
      activities.push({
        type: 'treasure_created',
        timestamp: treasure.created_at,
        user: treasure.creator,
        data: {
          treasure: {
            id: treasure.id,
            title: treasure.title,
            difficulty: treasure.difficulty,
            points: treasure.points
          }
        }
      });
    });

    activities.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));
    const paginatedActivities = activities.slice(0, parseInt(limit));

    await redisClient.setEx(cacheKey, 60, JSON.stringify(paginatedActivities));

    res.json(paginatedActivities);
  } catch (error) {
    console.error('Error fetching activity feed:', error);
    res.status(500).json({ error: 'Failed to fetch activity feed' });
  }
});

/**
 * @swagger
 * /api/activity/recent:
 *   get:
 *     summary: Get recent global activity
 *     tags: [Activity]
 */
router.get('/recent', async (req, res) => {
  try {
    const { limit = 10 } = req.query;
    const cacheKey = `activity:recent:${limit}`;

    const cached = await redisClient.get(cacheKey);
    if (cached) {
      return res.json(JSON.parse(cached));
    }

    const recentDiscoveries = await Discovery.findAll({
      include: [
        {
          model: User,
          attributes: ['id', 'username', 'avatar']
        },
        {
          model: Treasure,
          attributes: ['id', 'title', 'difficulty', 'points']
        }
      ],
      order: [['discovered_at', 'DESC']],
      limit: parseInt(limit)
    });

    const activities = recentDiscoveries.map(discovery => ({
      type: 'discovery',
      timestamp: discovery.discovered_at,
      user: discovery.User,
      treasure: discovery.Treasure,
      points_earned: discovery.points_earned
    }));

    await redisClient.setEx(cacheKey, 30, JSON.stringify(activities));

    res.json(activities);
  } catch (error) {
    console.error('Error fetching recent activity:', error);
    res.status(500).json({ error: 'Failed to fetch recent activity' });
  }
});

/**
 * @swagger
 * /api/activity/user/{userId}:
 *   get:
 *     summary: Get user activity
 *     tags: [Activity]
 */
router.get('/user/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const { limit = 20, offset = 0 } = req.query;

    const user = await User.findByPk(userId);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    const [discoveries, treasures] = await Promise.all([
      Discovery.findAll({
        where: { user_id: userId },
        include: [{
          model: Treasure,
          attributes: ['id', 'title', 'difficulty', 'points']
        }],
        order: [['discovered_at', 'DESC']],
        limit: parseInt(limit),
        offset: parseInt(offset)
      }),
      Treasure.findAll({
        where: {
          creator_id: userId,
          is_active: true,
          visibility: 'public'
        },
        attributes: ['id', 'title', 'difficulty', 'points', 'created_at'],
        order: [['created_at', 'DESC']],
        limit: parseInt(limit),
        offset: parseInt(offset)
      })
    ]);

    const activities = [];

    discoveries.forEach(discovery => {
      activities.push({
        type: 'discovery',
        timestamp: discovery.discovered_at,
        treasure: discovery.Treasure,
        points_earned: discovery.points_earned
      });
    });

    treasures.forEach(treasure => {
      activities.push({
        type: 'treasure_created',
        timestamp: treasure.created_at,
        treasure: {
          id: treasure.id,
          title: treasure.title,
          difficulty: treasure.difficulty,
          points: treasure.points
        }
      });
    });

    activities.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));

    res.json({
      user: {
        id: user.id,
        username: user.username,
        avatar: user.avatar
      },
      activities: activities.slice(0, parseInt(limit))
    });
  } catch (error) {
    console.error('Error fetching user activity:', error);
    res.status(500).json({ error: 'Failed to fetch user activity' });
  }
});

module.exports = router;