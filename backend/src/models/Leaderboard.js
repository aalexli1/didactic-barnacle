module.exports = (sequelize, DataTypes) => {
  const Leaderboard = sequelize.define('Leaderboard', {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true
    },
    user_id: {
      type: DataTypes.UUID,
      allowNull: false,
      references: {
        model: 'users',
        key: 'id'
      }
    },
    period_type: {
      type: DataTypes.ENUM('daily', 'weekly', 'monthly', 'all_time'),
      allowNull: false
    },
    period_start: {
      type: DataTypes.DATE,
      allowNull: false
    },
    period_end: {
      type: DataTypes.DATE,
      allowNull: true
    },
    points: {
      type: DataTypes.INTEGER,
      defaultValue: 0
    },
    treasures_found: {
      type: DataTypes.INTEGER,
      defaultValue: 0
    },
    treasures_created: {
      type: DataTypes.INTEGER,
      defaultValue: 0
    },
    streak_days: {
      type: DataTypes.INTEGER,
      defaultValue: 0
    },
    rank: {
      type: DataTypes.INTEGER,
      allowNull: true
    }
  }, {
    tableName: 'leaderboards',
    timestamps: true,
    underscored: true,
    indexes: [
      {
        fields: ['period_type', 'period_start', 'points']
      },
      {
        unique: true,
        fields: ['user_id', 'period_type', 'period_start']
      }
    ]
  });

  return Leaderboard;
};