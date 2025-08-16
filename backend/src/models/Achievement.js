module.exports = (sequelize, DataTypes) => {
  const Achievement = sequelize.define('Achievement', {
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
      allowNull: false
    },
    category: {
      type: DataTypes.ENUM('discovery', 'creation', 'social', 'exploration', 'special'),
      allowNull: false
    },
    icon: {
      type: DataTypes.STRING,
      allowNull: true
    },
    points: {
      type: DataTypes.INTEGER,
      defaultValue: 10
    },
    requirement_type: {
      type: DataTypes.ENUM('count', 'streak', 'unique', 'time_based', 'special'),
      allowNull: false
    },
    requirement_value: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    rarity: {
      type: DataTypes.ENUM('common', 'uncommon', 'rare', 'epic', 'legendary'),
      defaultValue: 'common'
    },
    is_active: {
      type: DataTypes.BOOLEAN,
      defaultValue: true
    }
  }, {
    tableName: 'achievements',
    timestamps: true,
    underscored: true
  });

  return Achievement;
};