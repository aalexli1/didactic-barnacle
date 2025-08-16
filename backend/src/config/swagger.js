const swaggerJsdoc = require('swagger-jsdoc');

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'AR Treasure Hunt API',
      version: '1.0.0',
      description: 'Backend API for AR Treasure Hunt iOS App',
      contact: {
        name: 'API Support',
        email: 'support@artreasure.app'
      }
    },
    servers: [
      {
        url: 'http://localhost:3000',
        description: 'Development server'
      },
      {
        url: 'https://api.artreasure.app',
        description: 'Production server'
      }
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT'
        }
      },
      schemas: {
        User: {
          type: 'object',
          properties: {
            id: { type: 'string', format: 'uuid' },
            username: { type: 'string' },
            email: { type: 'string', format: 'email' },
            avatar: { type: 'string' },
            bio: { type: 'string' },
            points: { type: 'integer' },
            treasures_created: { type: 'integer' },
            treasures_found: { type: 'integer' }
          }
        },
        Treasure: {
          type: 'object',
          properties: {
            id: { type: 'string', format: 'uuid' },
            title: { type: 'string' },
            description: { type: 'string' },
            message: { type: 'string' },
            latitude: { type: 'number' },
            longitude: { type: 'number' },
            ar_object: { type: 'object' },
            visibility: { type: 'string', enum: ['public', 'friends', 'private'] },
            difficulty: { type: 'string', enum: ['easy', 'medium', 'hard'] },
            points: { type: 'integer' },
            is_active: { type: 'boolean' }
          }
        },
        Discovery: {
          type: 'object',
          properties: {
            id: { type: 'string', format: 'uuid' },
            treasure_id: { type: 'string', format: 'uuid' },
            user_id: { type: 'string', format: 'uuid' },
            discovered_at: { type: 'string', format: 'date-time' },
            points_earned: { type: 'integer' }
          }
        },
        Notification: {
          type: 'object',
          properties: {
            id: { type: 'string', format: 'uuid' },
            type: { type: 'string' },
            title: { type: 'string' },
            message: { type: 'string' },
            is_read: { type: 'boolean' },
            created_at: { type: 'string', format: 'date-time' }
          }
        }
      }
    },
    tags: [
      { name: 'Auth', description: 'Authentication endpoints' },
      { name: 'Users', description: 'User management endpoints' },
      { name: 'Treasures', description: 'Treasure management endpoints' },
      { name: 'Friends', description: 'Friend management endpoints' },
      { name: 'Activity', description: 'Activity feed endpoints' },
      { name: 'Notifications', description: 'Notification endpoints' }
    ]
  },
  apis: ['./src/routes/*.js']
};

const swaggerSpec = swaggerJsdoc(options);

module.exports = swaggerSpec;