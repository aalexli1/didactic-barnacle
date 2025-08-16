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
models.Achievement = require('./Achievement')(sequelize, DataTypes);
models.UserAchievement = require('./UserAchievement')(sequelize, DataTypes);
models.Leaderboard = require('./Leaderboard')(sequelize, DataTypes);
models.TreasureMessage = require('./TreasureMessage')(sequelize, DataTypes);
models.Comment = require('./Comment')(sequelize, DataTypes);
models.Like = require('./Like')(sequelize, DataTypes);
models.Challenge = require('./Challenge')(sequelize, DataTypes);
models.ChallengeParticipant = require('./ChallengeParticipant')(sequelize, DataTypes);
models.Team = require('./Team')(sequelize, DataTypes);
models.TeamMember = require('./TeamMember')(sequelize, DataTypes);

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

// Achievement associations
models.User.belongsToMany(models.Achievement, {
  through: models.UserAchievement,
  foreignKey: 'user_id',
  otherKey: 'achievement_id'
});
models.Achievement.belongsToMany(models.User, {
  through: models.UserAchievement,
  foreignKey: 'achievement_id',
  otherKey: 'user_id'
});

// Leaderboard associations
models.User.hasMany(models.Leaderboard, { foreignKey: 'user_id' });
models.Leaderboard.belongsTo(models.User, { foreignKey: 'user_id' });

// Treasure Message associations
models.Treasure.hasMany(models.TreasureMessage, { foreignKey: 'treasure_id' });
models.TreasureMessage.belongsTo(models.Treasure, { foreignKey: 'treasure_id' });
models.User.hasMany(models.TreasureMessage, { foreignKey: 'user_id' });
models.TreasureMessage.belongsTo(models.User, { foreignKey: 'user_id' });

// Comment associations
models.Discovery.hasMany(models.Comment, { foreignKey: 'discovery_id' });
models.Comment.belongsTo(models.Discovery, { foreignKey: 'discovery_id' });
models.User.hasMany(models.Comment, { foreignKey: 'user_id' });
models.Comment.belongsTo(models.User, { foreignKey: 'user_id' });
models.Comment.hasMany(models.Comment, { as: 'replies', foreignKey: 'parent_comment_id' });
models.Comment.belongsTo(models.Comment, { as: 'parent', foreignKey: 'parent_comment_id' });

// Like associations
models.User.hasMany(models.Like, { foreignKey: 'user_id' });
models.Like.belongsTo(models.User, { foreignKey: 'user_id' });
models.Discovery.hasMany(models.Like, { foreignKey: 'discovery_id' });
models.Like.belongsTo(models.Discovery, { foreignKey: 'discovery_id' });
models.Comment.hasMany(models.Like, { foreignKey: 'comment_id' });
models.Like.belongsTo(models.Comment, { foreignKey: 'comment_id' });

// Challenge associations
models.User.hasMany(models.Challenge, { as: 'createdChallenges', foreignKey: 'creator_id' });
models.Challenge.belongsTo(models.User, { as: 'creator', foreignKey: 'creator_id' });
models.Challenge.hasMany(models.ChallengeParticipant, { foreignKey: 'challenge_id' });
models.ChallengeParticipant.belongsTo(models.Challenge, { foreignKey: 'challenge_id' });
models.User.hasMany(models.ChallengeParticipant, { foreignKey: 'user_id' });
models.ChallengeParticipant.belongsTo(models.User, { foreignKey: 'user_id' });

// Team associations
models.User.hasMany(models.Team, { as: 'captainedTeams', foreignKey: 'captain_id' });
models.Team.belongsTo(models.User, { as: 'captain', foreignKey: 'captain_id' });
models.Team.hasMany(models.TeamMember, { foreignKey: 'team_id' });
models.TeamMember.belongsTo(models.Team, { foreignKey: 'team_id' });
models.User.hasMany(models.TeamMember, { foreignKey: 'user_id' });
models.TeamMember.belongsTo(models.User, { foreignKey: 'user_id' });
models.Team.hasMany(models.ChallengeParticipant, { foreignKey: 'team_id' });
models.ChallengeParticipant.belongsTo(models.Team, { foreignKey: 'team_id' });

models.sequelize = sequelize;
models.Sequelize = Sequelize;

module.exports = models;