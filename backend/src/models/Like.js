module.exports = (sequelize, DataTypes) => {
  const Like = sequelize.define('Like', {
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
    discovery_id: {
      type: DataTypes.UUID,
      allowNull: true,
      references: {
        model: 'discoveries',
        key: 'id'
      }
    },
    comment_id: {
      type: DataTypes.UUID,
      allowNull: true,
      references: {
        model: 'comments',
        key: 'id'
      }
    },
    reaction_type: {
      type: DataTypes.ENUM('like', 'love', 'wow', 'celebrate'),
      defaultValue: 'like'
    }
  }, {
    tableName: 'likes',
    timestamps: true,
    underscored: true,
    indexes: [
      {
        unique: true,
        fields: ['user_id', 'discovery_id'],
        where: {
          discovery_id: {
            [sequelize.Op.ne]: null
          }
        }
      },
      {
        unique: true,
        fields: ['user_id', 'comment_id'],
        where: {
          comment_id: {
            [sequelize.Op.ne]: null
          }
        }
      }
    ]
  });

  return Like;
};