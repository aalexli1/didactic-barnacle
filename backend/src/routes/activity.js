const router = require('express').Router();
const { Op } = require('sequelize');
const { User, Treasure, Discovery, Friend, Comment, Like, Challenge, ChallengeParticipant, sequelize } = require('../models');
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

/**
 * @swagger
 * /api/activity/discovery/{id}/comment:
 *   post:
 *     summary: Add comment to discovery
 *     tags: [Activity]
 *     security:
 *       - bearerAuth: []
 */
router.post('/discovery/:id/comment', auth, async (req, res) => {
  try {
    const { content } = req.body;
    const { id } = req.params;

    const discovery = await Discovery.findByPk(id);
    if (!discovery) {
      return res.status(404).json({ error: 'Discovery not found' });
    }

    const comment = await Comment.create({
      discovery_id: id,
      user_id: req.user.id,
      content
    });

    const commentWithUser = await Comment.findByPk(comment.id, {
      include: [{
        model: User,
        attributes: ['id', 'username', 'avatar']
      }]
    });

    const GamificationService = require('../services/gamificationService');
    await GamificationService.addExperience(req.user.id, GamificationService.POINTS_CONFIG.COMMENT_POSTED, 'comment_posted');

    res.status(201).json(commentWithUser);
  } catch (error) {
    console.error('Error creating comment:', error);
    res.status(500).json({ error: 'Failed to create comment' });
  }
});

/**
 * @swagger
 * /api/activity/discovery/{id}/like:
 *   post:
 *     summary: Like/unlike discovery
 *     tags: [Activity]
 *     security:
 *       - bearerAuth: []
 */
router.post('/discovery/:id/like', auth, async (req, res) => {
  try {
    const { id } = req.params;
    const { reaction_type = 'like' } = req.body;

    const discovery = await Discovery.findByPk(id);
    if (!discovery) {
      return res.status(404).json({ error: 'Discovery not found' });
    }

    const existingLike = await Like.findOne({
      where: {
        user_id: req.user.id,
        discovery_id: id
      }
    });

    if (existingLike) {
      if (existingLike.reaction_type === reaction_type) {
        await existingLike.destroy();
        return res.json({ liked: false });
      } else {
        await existingLike.update({ reaction_type });
        return res.json({ liked: true, reaction_type });
      }
    }

    await Like.create({
      user_id: req.user.id,
      discovery_id: id,
      reaction_type
    });

    if (discovery.user_id !== req.user.id) {
      const GamificationService = require('../services/gamificationService');
      await GamificationService.addExperience(discovery.user_id, GamificationService.POINTS_CONFIG.LIKE_RECEIVED, 'like_received');
    }

    res.json({ liked: true, reaction_type });
  } catch (error) {
    console.error('Error toggling like:', error);
    res.status(500).json({ error: 'Failed to toggle like' });
  }
});

/**
 * @swagger
 * /api/activity/leaderboard/{period}:
 *   get:
 *     summary: Get leaderboard
 *     tags: [Activity]
 *     security:
 *       - bearerAuth: []
 */
router.get('/leaderboard/:period', auth, async (req, res) => {
  try {
    const { period } = req.params;
    const { limit = 100 } = req.query;
    
    const validPeriods = ['daily', 'weekly', 'monthly', 'all_time'];
    if (!validPeriods.includes(period)) {
      return res.status(400).json({ error: 'Invalid period' });
    }

    const GamificationService = require('../services/gamificationService');
    const leaderboard = await GamificationService.getLeaderboard(period, parseInt(limit));
    const userRank = await GamificationService.getUserRank(req.user.id, period);

    res.json({
      leaderboard,
      userRank,
      period
    });
  } catch (error) {
    console.error('Error fetching leaderboard:', error);
    res.status(500).json({ error: 'Failed to fetch leaderboard' });
  }
});

/**
 * @swagger
 * /api/activity/achievements:
 *   get:
 *     summary: Get user achievements
 *     tags: [Activity]
 *     security:
 *       - bearerAuth: []
 */
router.get('/achievements', auth, async (req, res) => {
  try {
    const { Achievement, UserAchievement } = require('../models');
    
    const achievements = await Achievement.findAll({
      where: { is_active: true },
      include: [{
        model: UserAchievement,
        where: { user_id: req.user.id },
        required: false
      }],
      order: [['category', 'ASC'], ['rarity', 'DESC']]
    });

    const formattedAchievements = achievements.map(achievement => ({
      id: achievement.id,
      name: achievement.name,
      description: achievement.description,
      category: achievement.category,
      icon: achievement.icon,
      points: achievement.points,
      rarity: achievement.rarity,
      progress: achievement.UserAchievements?.[0]?.progress || 0,
      requirement: achievement.requirement_value,
      completed: achievement.UserAchievements?.[0]?.completed || false,
      completedAt: achievement.UserAchievements?.[0]?.completed_at
    }));

    const stats = {
      total: achievements.length,
      completed: formattedAchievements.filter(a => a.completed).length,
      points: formattedAchievements.filter(a => a.completed).reduce((sum, a) => sum + a.points, 0)
    };

    res.json({
      achievements: formattedAchievements,
      stats
    });
  } catch (error) {
    console.error('Error fetching achievements:', error);
    res.status(500).json({ error: 'Failed to fetch achievements' });
  }
});

module.exports = router;