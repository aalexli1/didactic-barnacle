// Node.js Database Configuration Examples

// Using node-postgres (pg)
const { Pool } = require('pg');

const databaseConfig = {
  development: {
    host: 'localhost',
    port: 5432,
    database: 'myapp_development',
    user: 'postgres',
    password: process.env.DATABASE_PASSWORD,
    max: 10, // pool size
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 2000,
  },
  
  test: {
    host: 'localhost',
    port: 5432,
    database: 'myapp_test',
    user: 'postgres',
    password: process.env.DATABASE_PASSWORD,
    max: 5,
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 2000,
  },
  
  production: {
    host: process.env.DATABASE_HOST,
    port: parseInt(process.env.DATABASE_PORT) || 5432,
    database: process.env.DATABASE_NAME,
    user: process.env.DATABASE_USER,
    password: process.env.DATABASE_PASSWORD,
    max: 25, // pool size
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 5000,
    ssl: {
      rejectUnauthorized: false // Set to true in production with proper certificates
    }
  }
};

const environment = process.env.NODE_ENV || 'development';
const config = databaseConfig[environment];

const pool = new Pool(config);

// Error handling
pool.on('error', (err, client) => {
  console.error('Unexpected error on idle client', err);
  process.exit(-1);
});

module.exports = {
  pool,
  config,
  query: (text, params) => pool.query(text, params)
};

// Sequelize ORM Configuration
const sequelizeConfig = {
  development: {
    username: 'postgres',
    password: process.env.DATABASE_PASSWORD,
    database: 'myapp_development',
    host: 'localhost',
    port: 5432,
    dialect: 'postgres',
    logging: console.log,
    define: {
      timestamps: true,
      underscored: true
    }
  },
  
  test: {
    username: 'postgres',
    password: process.env.DATABASE_PASSWORD,
    database: 'myapp_test',
    host: 'localhost',
    port: 5432,
    dialect: 'postgres',
    logging: false,
    define: {
      timestamps: true,
      underscored: true
    }
  },
  
  production: {
    username: process.env.DATABASE_USER,
    password: process.env.DATABASE_PASSWORD,
    database: process.env.DATABASE_NAME,
    host: process.env.DATABASE_HOST,
    port: parseInt(process.env.DATABASE_PORT) || 5432,
    dialect: 'postgres',
    logging: false,
    pool: {
      max: 25,
      min: 0,
      acquire: 30000,
      idle: 10000
    },
    define: {
      timestamps: true,
      underscored: true
    }
  }
};

module.exports.sequelize = sequelizeConfig;