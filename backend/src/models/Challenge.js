module.exports = (sequelize, DataTypes) => {
  const Challenge = sequelize.define('Challenge', {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true
    },
    creator_id: {
      type: DataTypes.UUID,
      allowNull: false,
      references: {
        model: 'users',
        key: 'id'
      }
    },
    name: {
      type: DataTypes.STRING,
      allowNull: false
    },
    description: {
      type: DataTypes.TEXT,
      allowNull: false
    },
    challenge_type: {
      type: DataTypes.ENUM('treasure_chain', 'time_limited', 'photo_challenge', 'group_hunt', 'seasonal'),
      allowNull: false
    },
    start_date: {
      type: DataTypes.DATE,
      allowNull: false
    },
    end_date: {
      type: DataTypes.DATE,
      allowNull: false
    },
    max_participants: {
      type: DataTypes.INTEGER,
      allowNull: true
    },
    reward_points: {
      type: DataTypes.INTEGER,
      defaultValue: 100
    },
    difficulty: {
      type: DataTypes.ENUM('easy', 'medium', 'hard', 'expert'),
      defaultValue: 'medium'
    },
    requirements: {
      type: DataTypes.JSONB,
      defaultValue: {},
      comment: 'JSON object containing challenge-specific requirements'
    },
    is_public: {
      type: DataTypes.BOOLEAN,
      defaultValue: true
    },
    is_active: {
      type: DataTypes.BOOLEAN,
      defaultValue: true
    }
  }, {
    tableName: 'challenges',
    timestamps: true,
    underscored: true,
    indexes: [
      {
        fields: ['start_date', 'end_date']
      },
      {
        fields: ['challenge_type', 'is_active']
      }
    ]
  });

  return Challenge;
};