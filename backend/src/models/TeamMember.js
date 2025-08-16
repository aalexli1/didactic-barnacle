module.exports = (sequelize, DataTypes) => {
  const TeamMember = sequelize.define('TeamMember', {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true
    },
    team_id: {
      type: DataTypes.UUID,
      allowNull: false,
      references: {
        model: 'teams',
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
    role: {
      type: DataTypes.ENUM('captain', 'co_captain', 'member'),
      defaultValue: 'member'
    },
    contribution_points: {
      type: DataTypes.INTEGER,
      defaultValue: 0
    },
    joined_at: {
      type: DataTypes.DATE,
      defaultValue: DataTypes.NOW
    }
  }, {
    tableName: 'team_members',
    timestamps: true,
    underscored: true,
    indexes: [
      {
        unique: true,
        fields: ['team_id', 'user_id']
      }
    ]
  });

  return TeamMember;
};