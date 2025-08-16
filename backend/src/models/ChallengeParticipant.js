module.exports = (sequelize, DataTypes) => {
  const ChallengeParticipant = sequelize.define('ChallengeParticipant', {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true
    },
    challenge_id: {
      type: DataTypes.UUID,
      allowNull: false,
      references: {
        model: 'challenges',
        key: 'id'
      }
    },
    user_id: {
      type: DataTypes.UUID,
      allowNull: false,
      references: {
        model: 'users',
        key: 'id'
      }
    },
    team_id: {
      type: DataTypes.UUID,
      allowNull: true,
      references: {
        model: 'teams',
        key: 'id'
      }
    },
    progress: {
      type: DataTypes.JSONB,
      defaultValue: {},
      comment: 'JSON object tracking participant progress'
    },
    score: {
      type: DataTypes.INTEGER,
      defaultValue: 0
    },
    completed: {
      type: DataTypes.BOOLEAN,
      defaultValue: false
    },
    completed_at: {
      type: DataTypes.DATE,
      allowNull: true
    },
    rank: {
      type: DataTypes.INTEGER,
      allowNull: true
    }
  }, {
    tableName: 'challenge_participants',
    timestamps: true,
    underscored: true,
    indexes: [
      {
        unique: true,
        fields: ['challenge_id', 'user_id']
      },
      {
        fields: ['challenge_id', 'score']
      }
    ]
  });

  return ChallengeParticipant;
};