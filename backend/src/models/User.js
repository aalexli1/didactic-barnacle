module.exports = (sequelize, DataTypes) => {
  const User = sequelize.define('User', {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true
    },
    username: {
      type: DataTypes.STRING,
      allowNull: false,
      unique: true,
      validate: {
        len: [3, 30]
      }
    },
    email: {
      type: DataTypes.STRING,
      allowNull: false,
      unique: true,
      validate: {
        isEmail: true
      }
    },
    password: {
      type: DataTypes.STRING,
      allowNull: false
    },
    avatar: {
      type: DataTypes.STRING,
      allowNull: true
    },
    bio: {
      type: DataTypes.TEXT,
      allowNull: true
    },
    level: {
      type: DataTypes.INTEGER,
      defaultValue: 1,
      allowNull: false
    },
    experience: {
      type: DataTypes.INTEGER,
      defaultValue: 0,
      allowNull: false
    },
    treasures_created: {
      type: DataTypes.INTEGER,
      defaultValue: 0
    },
    treasures_found: {
      type: DataTypes.INTEGER,
      defaultValue: 0
    },
    points: {
      type: DataTypes.INTEGER,
      defaultValue: 0
    },
    settings: {
      type: DataTypes.JSONB,
      defaultValue: {
        notificationsEnabled: true,
        locationSharingEnabled: true,
        privateProfile: false,
        discoveryRadius: 1000
      },
      allowNull: false
    },
    is_active: {
      type: DataTypes.BOOLEAN,
      defaultValue: true
    }
  }, {
    tableName: 'users',
    timestamps: true,
    underscored: true
  });

  return User;
};