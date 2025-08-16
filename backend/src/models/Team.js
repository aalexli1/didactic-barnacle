module.exports = (sequelize, DataTypes) => {
  const Team = sequelize.define('Team', {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true
    },
    name: {
      type: DataTypes.STRING,
      allowNull: false
    },
    description: {
      type: DataTypes.TEXT,
      allowNull: true
    },
    captain_id: {
      type: DataTypes.UUID,
      allowNull: false,
      references: {
        model: 'users',
        key: 'id'
      }
    },
    avatar: {
      type: DataTypes.STRING,
      allowNull: true
    },
    color: {
      type: DataTypes.STRING,
      defaultValue: '#007AFF'
    },
    max_members: {
      type: DataTypes.INTEGER,
      defaultValue: 10
    },
    is_public: {
      type: DataTypes.BOOLEAN,
      defaultValue: true
    },
    invite_code: {
      type: DataTypes.STRING,
      unique: true,
      allowNull: true
    },
    total_points: {
      type: DataTypes.INTEGER,
      defaultValue: 0
    },
    is_active: {
      type: DataTypes.BOOLEAN,
      defaultValue: true
    }
  }, {
    tableName: 'teams',
    timestamps: true,
    underscored: true,
    indexes: [
      {
        unique: true,
        fields: ['invite_code']
      }
    ]
  });

  return Team;
};