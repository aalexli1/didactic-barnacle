const router = require('express').Router();
const { body, param, validationResult } = require('express-validator');
const { Op } = require('sequelize');
const { User, Friend, Notification } = require('../models');
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
 * /api/friends/add:
 *   post:
 *     summary: Send friend request
 *     tags: [Friends]
 *     security:
 *       - bearerAuth: []
 */
router.post('/add',
  auth,
  [
    body('username').optional().isString(),
    body('user_id').optional().isUUID()
  ],
  handleValidationErrors,
  async (req, res) => {
    try {
      const { username, user_id } = req.body;

      if (!username && !user_id) {
        return res.status(400).json({ error: 'Username or user_id required' });
      }

      const friend = await User.findOne({
        where: username ? { username } : { id: user_id }
      });

      if (!friend) {
        return res.status(404).json({ error: 'User not found' });
      }

      if (friend.id === req.user.id) {
        return res.status(400).json({ error: 'Cannot add yourself as a friend' });
      }

      const existingFriendship = await Friend.findOne({
        where: {
          [Op.or]: [
            { user_id: req.user.id, friend_id: friend.id },
            { user_id: friend.id, friend_id: req.user.id }
          ]
        }
      });

      if (existingFriendship) {
        return res.status(400).json({ 
          error: 'Friend request already exists',
          status: existingFriendship.status 
        });
      }

      const friendRequest = await Friend.create({
        user_id: req.user.id,
        friend_id: friend.id,
        status: 'pending'
      });

      const requester = await User.findByPk(req.user.id, {
        attributes: ['username']
      });

      await Notification.create({
        user_id: friend.id,
        type: 'friend_request',
        title: 'New Friend Request',
        message: `${requester.username} wants to be your friend!`,
        data: {
          request_id: friendRequest.id,
          user_id: req.user.id,
          username: requester.username
        }
      });

      res.status(201).json({
        success: true,
        message: 'Friend request sent',
        request: friendRequest
      });
    } catch (error) {
      console.error('Error sending friend request:', error);
      res.status(500).json({ error: 'Failed to send friend request' });
    }
  }
);

/**
 * @swagger
 * /api/friends/requests:
 *   get:
 *     summary: Get pending friend requests
 *     tags: [Friends]
 *     security:
 *       - bearerAuth: []
 */
router.get('/requests', auth, async (req, res) => {
  try {
    const requests = await Friend.findAll({
      where: {
        friend_id: req.user.id,
        status: 'pending'
      },
      include: [{
        model: User,
        as: 'requester',
        attributes: ['id', 'username', 'avatar', 'points']
      }],
      order: [['requested_at', 'DESC']]
    });

    res.json(requests);
  } catch (error) {
    console.error('Error fetching friend requests:', error);
    res.status(500).json({ error: 'Failed to fetch friend requests' });
  }
});

/**
 * @swagger
 * /api/friends/accept/{requestId}:
 *   put:
 *     summary: Accept friend request
 *     tags: [Friends]
 *     security:
 *       - bearerAuth: []
 */
router.put('/accept/:requestId',
  auth,
  [param('requestId').isUUID()],
  handleValidationErrors,
  async (req, res) => {
    try {
      const friendRequest = await Friend.findOne({
        where: {
          id: req.params.requestId,
          friend_id: req.user.id,
          status: 'pending'
        }
      });

      if (!friendRequest) {
        return res.status(404).json({ error: 'Friend request not found' });
      }

      await friendRequest.update({
        status: 'accepted',
        accepted_at: new Date()
      });

      const accepter = await User.findByPk(req.user.id, {
        attributes: ['username']
      });

      await Notification.create({
        user_id: friendRequest.user_id,
        type: 'friend_accepted',
        title: 'Friend Request Accepted',
        message: `${accepter.username} accepted your friend request!`,
        data: {
          user_id: req.user.id,
          username: accepter.username
        }
      });

      res.json({
        success: true,
        message: 'Friend request accepted'
      });
    } catch (error) {
      console.error('Error accepting friend request:', error);
      res.status(500).json({ error: 'Failed to accept friend request' });
    }
  }
);

/**
 * @swagger
 * /api/friends/reject/{requestId}:
 *   delete:
 *     summary: Reject friend request
 *     tags: [Friends]
 *     security:
 *       - bearerAuth: []
 */
router.delete('/reject/:requestId',
  auth,
  [param('requestId').isUUID()],
  handleValidationErrors,
  async (req, res) => {
    try {
      const friendRequest = await Friend.findOne({
        where: {
          id: req.params.requestId,
          friend_id: req.user.id,
          status: 'pending'
        }
      });

      if (!friendRequest) {
        return res.status(404).json({ error: 'Friend request not found' });
      }

      await friendRequest.destroy();

      res.json({
        success: true,
        message: 'Friend request rejected'
      });
    } catch (error) {
      console.error('Error rejecting friend request:', error);
      res.status(500).json({ error: 'Failed to reject friend request' });
    }
  }
);

/**
 * @swagger
 * /api/friends/remove/{friendId}:
 *   delete:
 *     summary: Remove friend
 *     tags: [Friends]
 *     security:
 *       - bearerAuth: []
 */
router.delete('/remove/:friendId',
  auth,
  [param('friendId').isUUID()],
  handleValidationErrors,
  async (req, res) => {
    try {
      const friendship = await Friend.findOne({
        where: {
          [Op.or]: [
            { user_id: req.user.id, friend_id: req.params.friendId },
            { user_id: req.params.friendId, friend_id: req.user.id }
          ],
          status: 'accepted'
        }
      });

      if (!friendship) {
        return res.status(404).json({ error: 'Friendship not found' });
      }

      await friendship.destroy();

      res.json({
        success: true,
        message: 'Friend removed'
      });
    } catch (error) {
      console.error('Error removing friend:', error);
      res.status(500).json({ error: 'Failed to remove friend' });
    }
  }
);

Friend.belongsTo(User, { as: 'requester', foreignKey: 'user_id' });
Friend.belongsTo(User, { as: 'requested', foreignKey: 'friend_id' });

module.exports = router;