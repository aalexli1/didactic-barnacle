const { sequelize } = require('../models');

const migrate = async () => {
  try {
    console.log('Starting database migration...');
    
    await sequelize.authenticate();
    console.log('Database connection established.');
    
    await sequelize.sync({ alter: true });
    console.log('Database synchronized successfully.');
    
    await sequelize.query('SELECT create_spatial_indexes()');
    console.log('Spatial indexes created.');
    
    process.exit(0);
  } catch (error) {
    console.error('Migration failed:', error);
    process.exit(1);
  }
};

migrate();