module.exports = (sequelize, DataTypes) => {
  const Discovery = sequelize.define('Discovery', {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true
    },
    treasure_id: {
      type: DataTypes.UUID,
      allowNull: false,
      references: {
        model: 'treasures',
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
    discovered_at: {
      type: DataTypes.DATE,
      defaultValue: DataTypes.NOW
    },
    points_earned: {
      type: DataTypes.INTEGER,
      defaultValue: 0
    },
    time_to_find: {
      type: DataTypes.INTEGER,
      allowNull: true,
      comment: 'Time in seconds from treasure creation to discovery'
    },
    distance_from_treasure: {
      type: DataTypes.FLOAT,
      allowNull: true,
      comment: 'Distance in meters when discovered'
    },
    photo_url: {
      type: DataTypes.STRING,
      allowNull: true
    },
    comment: {
      type: DataTypes.TEXT,
      allowNull: true
    },
    reaction_type: {
      type: DataTypes.ENUM('like', 'love', 'wow', 'funny', 'cool'),
      allowNull: true
    }
  }, {
    tableName: 'discoveries',
    timestamps: true,
    underscored: true,
    indexes: [
      {
        unique: true,
        fields: ['treasure_id', 'user_id']
      }
    ]
  });

  return Discovery;
};