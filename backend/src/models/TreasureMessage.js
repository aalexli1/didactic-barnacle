module.exports = (sequelize, DataTypes) => {
  const TreasureMessage = sequelize.define('TreasureMessage', {
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
    message_type: {
      type: DataTypes.ENUM('text', 'voice', 'photo', 'video'),
      defaultValue: 'text'
    },
    content: {
      type: DataTypes.TEXT,
      allowNull: true
    },
    media_url: {
      type: DataTypes.STRING,
      allowNull: true
    },
    duration: {
      type: DataTypes.INTEGER,
      allowNull: true,
      comment: 'Duration in seconds for voice/video messages'
    },
    is_encrypted: {
      type: DataTypes.BOOLEAN,
      defaultValue: false
    },
    is_deleted: {
      type: DataTypes.BOOLEAN,
      defaultValue: false
    }
  }, {
    tableName: 'treasure_messages',
    timestamps: true,
    underscored: true,
    indexes: [
      {
        fields: ['treasure_id', 'created_at']
      }
    ]
  });

  return TreasureMessage;
};