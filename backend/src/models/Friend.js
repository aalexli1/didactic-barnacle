module.exports = (sequelize, DataTypes) => {
  const Friend = sequelize.define('Friend', {
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
    friend_id: {
      type: DataTypes.UUID,
      allowNull: false,
      references: {
        model: 'users',
        key: 'id'
      }
    },
    status: {
      type: DataTypes.ENUM('pending', 'accepted', 'blocked'),
      defaultValue: 'pending'
    },
    requested_at: {
      type: DataTypes.DATE,
      defaultValue: DataTypes.NOW
    },
    accepted_at: {
      type: DataTypes.DATE,
      allowNull: true
    }
  }, {
    tableName: 'friends',
    timestamps: true,
    underscored: true,
    indexes: [
      {
        unique: true,
        fields: ['user_id', 'friend_id']
      }
    ]
  });

  return Friend;
};