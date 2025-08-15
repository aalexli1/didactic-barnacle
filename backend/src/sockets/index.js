const jwt = require('jsonwebtoken');
const { User } = require('../models');

module.exports = (io) => {
  io.use(async (socket, next) => {
    try {
      const token = socket.handshake.auth.token;
      if (!token) {
        return next(new Error('Authentication error'));
      }

      const decoded = jwt.verify(token, process.env.JWT_SECRET || 'secret');
      const user = await User.findByPk(decoded.id, {
        attributes: ['id', 'username', 'is_active']
      });

      if (!user || !user.is_active) {
        return next(new Error('Authentication error'));
      }

      socket.userId = user.id;
      socket.username = user.username;
      next();
    } catch (err) {
      next(new Error('Authentication error'));
    }
  });

  io.on('connection', (socket) => {
    console.log(`User ${socket.username} connected`);

    socket.join(`user:${socket.userId}`);

    socket.on('join-room', (room) => {
      const allowedRooms = ['global', 'friends', `user:${socket.userId}`];
      if (allowedRooms.includes(room)) {
        socket.join(room);
        console.log(`User ${socket.username} joined room: ${room}`);
      }
    });

    socket.on('leave-room', (room) => {
      socket.leave(room);
      console.log(`User ${socket.username} left room: ${room}`);
    });

    socket.on('treasure-created', async (data) => {
      try {
        io.to('global').emit('new-treasure', {
          ...data,
          creator: {
            id: socket.userId,
            username: socket.username
          }
        });

        const { Friend } = require('../models');
        const friends = await Friend.findAll({
          where: {
            [require('sequelize').Op.or]: [
              { user_id: socket.userId, status: 'accepted' },
              { friend_id: socket.userId, status: 'accepted' }
            ]
          }
        });

        friends.forEach(friend => {
          const friendId = friend.user_id === socket.userId ? friend.friend_id : friend.user_id;
          io.to(`user:${friendId}`).emit('friend-treasure-created', {
            ...data,
            creator: {
              id: socket.userId,
              username: socket.username
            }
          });
        });
      } catch (error) {
        console.error('Error broadcasting treasure creation:', error);
      }
    });

    socket.on('treasure-found', async (data) => {
      try {
        io.to('global').emit('treasure-discovered', {
          ...data,
          discoverer: {
            id: socket.userId,
            username: socket.username
          }
        });
      } catch (error) {
        console.error('Error broadcasting treasure discovery:', error);
      }
    });

    socket.on('location-update', async (data) => {
      try {
        socket.broadcast.to('friends').emit('friend-location', {
          userId: socket.userId,
          username: socket.username,
          latitude: data.latitude,
          longitude: data.longitude,
          timestamp: new Date()
        });
      } catch (error) {
        console.error('Error broadcasting location update:', error);
      }
    });

    socket.on('disconnect', () => {
      console.log(`User ${socket.username} disconnected`);
      
      socket.broadcast.to('friends').emit('friend-offline', {
        userId: socket.userId,
        username: socket.username
      });
    });

    socket.on('error', (error) => {
      console.error(`Socket error for user ${socket.username}:`, error);
    });
  });

  return io;
};