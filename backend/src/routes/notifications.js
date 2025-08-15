const router = require('express').Router();
const { body, param, validationResult } = require('express-validator');
const { Notification } = require('../models');
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
 * /api/notifications:
 *   get:
 *     summary: Get user notifications
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 */
router.get('/', auth, async (req, res) => {
  try {
    const { limit = 50, offset = 0, unread_only = false } = req.query;

    const where = { user_id: req.user.id };
    if (unread_only === 'true') {
      where.is_read = false;
    }

    const notifications = await Notification.findAll({
      where,
      order: [['created_at', 'DESC']],
      limit: parseInt(limit),
      offset: parseInt(offset)
    });

    const unreadCount = await Notification.count({
      where: {
        user_id: req.user.id,
        is_read: false
      }
    });

    res.json({
      notifications,
      unread_count: unreadCount
    });
  } catch (error) {
    console.error('Error fetching notifications:', error);
    res.status(500).json({ error: 'Failed to fetch notifications' });
  }
});

/**
 * @swagger
 * /api/notifications/send:
 *   post:
 *     summary: Send notification (internal use)
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 */
router.post('/send',
  auth,
  [
    body('user_id').isUUID(),
    body('type').isIn([
      'treasure_found',
      'friend_request',
      'friend_accepted',
      'new_treasure_nearby',
      'achievement_unlocked',
      'treasure_expired'
    ]),
    body('title').notEmpty(),
    body('message').notEmpty()
  ],
  handleValidationErrors,
  async (req, res) => {
    try {
      const notification = await Notification.create(req.body);
      
      const io = req.app.get('io');
      if (io) {
        io.to(`user:${req.body.user_id}`).emit('notification', notification);
      }

      res.status(201).json(notification);
    } catch (error) {
      console.error('Error sending notification:', error);
      res.status(500).json({ error: 'Failed to send notification' });
    }
  }
);

/**
 * @swagger
 * /api/notifications/{id}/read:
 *   put:
 *     summary: Mark notification as read
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 */
router.put('/:id/read',
  auth,
  [param('id').isUUID()],
  handleValidationErrors,
  async (req, res) => {
    try {
      const notification = await Notification.findOne({
        where: {
          id: req.params.id,
          user_id: req.user.id
        }
      });

      if (!notification) {
        return res.status(404).json({ error: 'Notification not found' });
      }

      await notification.update({
        is_read: true,
        read_at: new Date()
      });

      res.json({ success: true });
    } catch (error) {
      console.error('Error marking notification as read:', error);
      res.status(500).json({ error: 'Failed to mark notification as read' });
    }
  }
);

/**
 * @swagger
 * /api/notifications/read-all:
 *   put:
 *     summary: Mark all notifications as read
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 */
router.put('/read-all', auth, async (req, res) => {
  try {
    await Notification.update(
      {
        is_read: true,
        read_at: new Date()
      },
      {
        where: {
          user_id: req.user.id,
          is_read: false
        }
      }
    );

    res.json({ success: true });
  } catch (error) {
    console.error('Error marking all notifications as read:', error);
    res.status(500).json({ error: 'Failed to mark all notifications as read' });
  }
});

/**
 * @swagger
 * /api/notifications/{id}:
 *   delete:
 *     summary: Delete notification
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 */
router.delete('/:id',
  auth,
  [param('id').isUUID()],
  handleValidationErrors,
  async (req, res) => {
    try {
      const notification = await Notification.findOne({
        where: {
          id: req.params.id,
          user_id: req.user.id
        }
      });

      if (!notification) {
        return res.status(404).json({ error: 'Notification not found' });
      }

      await notification.destroy();

      res.json({ success: true });
    } catch (error) {
      console.error('Error deleting notification:', error);
      res.status(500).json({ error: 'Failed to delete notification' });
    }
  }
);

module.exports = router;