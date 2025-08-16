module.exports = (sequelize, DataTypes) => {
  const Treasure = sequelize.define('Treasure', {
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
    title: {
      type: DataTypes.STRING,
      allowNull: false
    },
    description: {
      type: DataTypes.TEXT,
      allowNull: true
    },
    message: {
      type: DataTypes.TEXT,
      allowNull: true
    },
    location: {
      type: DataTypes.GEOMETRY('POINT'),
      allowNull: false
    },
    latitude: {
      type: DataTypes.FLOAT,
      allowNull: false,
      validate: {
        min: -90,
        max: 90
      }
    },
    longitude: {
      type: DataTypes.FLOAT,
      allowNull: false,
      validate: {
        min: -180,
        max: 180
      }
    },
    altitude: {
      type: DataTypes.FLOAT,
      defaultValue: 0,
      allowNull: false
    },
    type: {
      type: DataTypes.ENUM('standard', 'premium', 'special', 'event'),
      defaultValue: 'standard',
      allowNull: false
    },
    media_url: {
      type: DataTypes.STRING,
      allowNull: true
    },
    ar_object: {
      type: DataTypes.JSONB,
      allowNull: true,
      defaultValue: {
        type: 'default',
        modelUrl: null,
        color: '#FFD700',
        scale: 1.0
      }
    },
    visibility: {
      type: DataTypes.ENUM('public', 'friends', 'private'),
      defaultValue: 'public'
    },
    difficulty: {
      type: DataTypes.ENUM('easy', 'medium', 'hard'),
      defaultValue: 'medium'
    },
    hint: {
      type: DataTypes.TEXT,
      allowNull: true
    },
    points: {
      type: DataTypes.INTEGER,
      defaultValue: 10
    },
    max_discoveries: {
      type: DataTypes.INTEGER,
      allowNull: true
    },
    is_active: {
      type: DataTypes.BOOLEAN,
      defaultValue: true
    },
    expires_at: {
      type: DataTypes.DATE,
      allowNull: true
    }
  }, {
    tableName: 'treasures',
    timestamps: true,
    underscored: true,
    hooks: {
      beforeSave: (treasure) => {
        if (treasure.latitude && treasure.longitude) {
          treasure.location = {
            type: 'Point',
            coordinates: [treasure.longitude, treasure.latitude]
          };
        }
      }
    }
  });

  return Treasure;
};