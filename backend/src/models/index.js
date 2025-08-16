const { Sequelize, DataTypes } = require('sequelize');
const config = require('../config/database');

const env = process.env.NODE_ENV || 'development';
const dbConfig = config[env];

const sequelize = new Sequelize(
  dbConfig.database,
  dbConfig.username,
  dbConfig.password,
  dbConfig
);

const models = {};

models.User = require('./User')(sequelize, DataTypes);
models.Treasure = require('./Treasure')(sequelize, DataTypes);
models.Discovery = require('./Discovery')(sequelize, DataTypes);
models.Friend = require('./Friend')(sequelize, DataTypes);
models.Notification = require('./Notification')(sequelize, DataTypes);
models.SyncMetadata = require('./SyncMetadata')(sequelize, DataTypes);

models.User.hasMany(models.Treasure, { as: 'createdTreasures', foreignKey: 'creator_id' });
models.Treasure.belongsTo(models.User, { as: 'creator', foreignKey: 'creator_id' });

models.User.belongsToMany(models.Treasure, {
  through: models.Discovery,
  as: 'discoveredTreasures',
  foreignKey: 'user_id',
  otherKey: 'treasure_id'
});
models.Treasure.belongsToMany(models.User, {
  through: models.Discovery,
  as: 'discoverers',
  foreignKey: 'treasure_id',
  otherKey: 'user_id'
});

models.User.belongsToMany(models.User, {
  through: models.Friend,
  as: 'friends',
  foreignKey: 'user_id',
  otherKey: 'friend_id'
});

models.User.hasMany(models.Notification, { foreignKey: 'user_id' });
models.Notification.belongsTo(models.User, { foreignKey: 'user_id' });

models.sequelize = sequelize;
models.Sequelize = Sequelize;

module.exports = models;