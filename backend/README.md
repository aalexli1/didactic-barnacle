# AR Treasure Hunt Backend API

Backend API service for the AR Treasure Hunt iOS application, providing treasure management, user authentication, social features, and real-time updates.

## Features

- **User Management**: Registration, authentication, profiles
- **Treasure Management**: Create, discover, and manage AR treasures with geospatial queries
- **Social Features**: Friends system, activity feeds, notifications
- **Real-time Updates**: WebSocket support for live treasure discoveries and friend locations
- **Geospatial Queries**: PostGIS integration for location-based treasure finding
- **Caching**: Redis integration for performance optimization
- **API Documentation**: Swagger/OpenAPI documentation

## Tech Stack

- **Node.js/Express**: REST API server
- **PostgreSQL + PostGIS**: Database with geospatial support
- **Redis**: Caching and session management
- **Socket.io**: Real-time WebSocket connections
- **JWT**: Authentication tokens
- **Sequelize**: ORM for database operations
- **Docker**: Containerization for development

## Prerequisites

- Node.js 18+
- Docker and Docker Compose
- PostgreSQL 15+ with PostGIS extension (or use Docker)
- Redis (or use Docker)

## Quick Start

### Using Docker (Recommended)

1. Clone the repository
2. Navigate to backend directory:
   ```bash
   cd backend
   ```

3. Start services with Docker Compose:
   ```bash
   docker-compose up -d
   ```

4. Install dependencies:
   ```bash
   npm install
   ```

5. Run database migrations:
   ```bash
   npm run migrate
   ```

6. Access the API:
   - API: http://localhost:3000
   - API Docs: http://localhost:3000/api-docs

### Manual Setup

1. Install PostgreSQL with PostGIS extension
2. Install Redis
3. Copy environment variables:
   ```bash
   cp .env.example .env
   ```
4. Update `.env` with your database credentials
5. Install dependencies:
   ```bash
   npm install
   ```
6. Run migrations:
   ```bash
   npm run migrate
   ```
7. Start the server:
   ```bash
   npm run dev
   ```

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user

### Treasures
- `POST /api/treasures` - Create treasure
- `GET /api/treasures/nearby` - Get nearby treasures
- `GET /api/treasures/:id` - Get treasure details
- `PUT /api/treasures/:id/found` - Mark treasure as found
- `DELETE /api/treasures/:id` - Delete treasure

### Users
- `GET /api/users/profile` - Get user profile
- `PUT /api/users/profile` - Update profile
- `GET /api/users/friends` - Get friends list
- `GET /api/users/leaderboard` - Get leaderboard
- `GET /api/users/stats` - Get user statistics

### Friends
- `POST /api/friends/add` - Send friend request
- `GET /api/friends/requests` - Get pending requests
- `PUT /api/friends/accept/:id` - Accept friend request
- `DELETE /api/friends/reject/:id` - Reject friend request
- `DELETE /api/friends/remove/:id` - Remove friend

### Activity
- `GET /api/activity/feed` - Get activity feed
- `GET /api/activity/recent` - Get recent global activity
- `GET /api/activity/user/:id` - Get user activity

### Notifications
- `GET /api/notifications` - Get notifications
- `PUT /api/notifications/:id/read` - Mark as read
- `PUT /api/notifications/read-all` - Mark all as read
- `DELETE /api/notifications/:id` - Delete notification

## WebSocket Events

### Client -> Server
- `join-room` - Join a room (global, friends)
- `treasure-created` - Broadcast new treasure
- `treasure-found` - Broadcast treasure discovery
- `location-update` - Share location with friends

### Server -> Client
- `new-treasure` - New treasure created
- `treasure-discovered` - Treasure found by someone
- `friend-location` - Friend location update
- `friend-offline` - Friend went offline
- `notification` - New notification

## Environment Variables

```env
# Server
PORT=3000
NODE_ENV=development

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=ar_treasure_hunt
DB_USER=postgres
DB_PASSWORD=your_password

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379

# JWT
JWT_SECRET=your_secret_key
JWT_EXPIRES_IN=7d
```

## Development

```bash
# Install dependencies
npm install

# Run development server
npm run dev

# Run tests
npm test

# Run migrations
npm run migrate
```

## Docker Commands

```bash
# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# View logs
docker-compose logs -f backend

# Rebuild containers
docker-compose build
```

## Project Structure

```
backend/
├── src/
│   ├── config/        # Configuration files
│   ├── db/           # Database migrations
│   ├── middleware/   # Express middleware
│   ├── models/       # Sequelize models
│   ├── routes/       # API routes
│   ├── sockets/      # WebSocket handlers
│   └── server.js     # Main server file
├── docker-compose.yml
├── Dockerfile
├── package.json
└── README.md
```

## License

MIT