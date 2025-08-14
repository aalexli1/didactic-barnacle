# User API Integration Tests

This directory contains comprehensive integration tests for the user management API endpoints. The test suite covers CRUD operations, error handling, edge cases, and performance testing.

## Overview

The integration tests are designed to work with the user API endpoints defined in issue #20. They provide comprehensive coverage of:

- **CRUD Operations**: Create, Read, Update, Delete functionality
- **Authentication & Authorization**: Token-based auth and permission testing
- **Error Handling**: 400, 401, 403, 404 status codes
- **Edge Cases**: Special characters, boundary values, concurrent operations
- **Performance**: Response times, concurrent requests, load testing

## Test Structure

```
tests/integration/
├── package.json           # Dependencies and scripts
├── jest.config.js         # Jest configuration
├── tsconfig.json         # TypeScript configuration
├── setup/
│   └── test-setup.ts     # Global test setup and configuration
├── types/
│   └── test-config.ts    # TypeScript interfaces and types
├── utils/
│   └── api-client.ts     # HTTP client for API calls
├── tests/
│   ├── user-crud.test.ts      # CRUD operations tests
│   ├── user-auth.test.ts      # Authentication/authorization tests
│   ├── user-edge-cases.test.ts # Edge cases and boundary testing
│   └── user-performance.test.ts # Performance and load tests
└── load-tests/
    ├── user-api-load.yml      # Artillery load test configuration
    └── load-test-functions.js # Custom functions for load testing
```

## Prerequisites

1. **API Server**: The user API server must be running (default: http://localhost:3000)
2. **Authentication**: Valid admin and user tokens must be available
3. **Database**: Clean database state for consistent test results

## Setup

1. Install dependencies:
```bash
cd tests/integration
npm install
```

2. Set environment variables:
```bash
export API_BASE_URL="http://localhost:3000"
export ADMIN_TOKEN="your-admin-token"
export USER_TOKEN="your-user-token"
```

## Running Tests

### Unit Tests (Jest)

Run all tests:
```bash
npm test
```

Run specific test suites:
```bash
npm test user-crud.test.ts
npm test user-auth.test.ts
npm test user-edge-cases.test.ts
npm test user-performance.test.ts
```

Run tests in watch mode:
```bash
npm run test:watch
```

Generate coverage report:
```bash
npm run test:coverage
```

### Load Tests (Artillery)

Run load tests:
```bash
npm run test:load
```

Run with custom configuration:
```bash
artillery run load-tests/user-api-load.yml --environment production
```

## Test Categories

### 1. CRUD Operations (`user-crud.test.ts`)

Tests all basic user management operations:

- **Create User (POST /api/users)**
  - Valid user creation
  - Missing required fields (400)
  - Duplicate email handling (409)

- **Read Users (GET /api/users, GET /api/users/:id)**
  - List all users with pagination
  - Get user by ID
  - Non-existent user (404)
  - Pagination support

- **Update User (PUT /api/users/:id)**
  - Update with valid data
  - Non-existent user (404)
  - Invalid data (400)

- **Delete User (DELETE /api/users/:id)**
  - Successful deletion
  - Non-existent user (404)

### 2. Authentication & Authorization (`user-auth.test.ts`)

Tests security and access control:

- **Authentication (401 Unauthorized)**
  - No token provided
  - Invalid token
  - Expired token

- **Authorization (403 Forbidden)**
  - Regular user attempting admin operations
  - Cross-user data access attempts

- **Not Found (404)**
  - Invalid user IDs
  - Malformed IDs

- **Bad Request (400)**
  - Invalid email formats
  - Missing required fields
  - Invalid pagination parameters

### 3. Edge Cases (`user-edge-cases.test.ts`)

Tests boundary conditions and special scenarios:

- **Empty and Null Fields**
  - Empty strings, null values, undefined values
  - Whitespace-only strings

- **Special Characters**
  - Unicode characters, emojis
  - Script injection attempts
  - Special characters in names

- **Boundary Values**
  - Maximum/minimum length strings
  - Case sensitivity testing

- **Email Edge Cases**
  - Plus signs, dots in emails
  - International domain names
  - Invalid email formats

- **Concurrent Operations**
  - Race conditions
  - Duplicate creation attempts

### 4. Performance Tests (`user-performance.test.ts`)

Tests system performance and scalability:

- **Response Time Tests**
  - Individual endpoint response times
  - Acceptable performance thresholds

- **Concurrent Request Tests**
  - Multiple simultaneous requests
  - Concurrent user creation

- **Pagination Performance**
  - Large page sizes
  - Multiple page requests

- **Memory and Resource Tests**
  - Bulk operations
  - Performance with growing datasets

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `API_BASE_URL` | Base URL for the API server | `http://localhost:3000` |
| `ADMIN_TOKEN` | Authentication token for admin operations | `test-admin-token` |
| `USER_TOKEN` | Authentication token for regular user operations | `test-user-token` |

### Test Configuration

The test configuration is defined in `setup/test-setup.ts`:

```typescript
export const testConfig: TestConfig = {
  baseUrl: process.env.API_BASE_URL || 'http://localhost:3000',
  timeout: 30000,
  retries: 3,
  auth: {
    adminToken: process.env.ADMIN_TOKEN || 'test-admin-token',
    userToken: process.env.USER_TOKEN || 'test-user-token'
  }
};
```

## API Client

The `ApiClient` class in `utils/api-client.ts` provides a convenient interface for making API calls:

```typescript
const apiClient = new ApiClient();
const adminToken = await apiClient.authenticateAsAdmin();

// Create user
const response = await apiClient.createUser(userData, adminToken);

// Get all users
const users = await apiClient.getUsers(adminToken);

// Get user by ID
const user = await apiClient.getUserById(userId, adminToken);
```

## Expected API Behavior

The tests expect the following API behavior:

### User Object Structure
```typescript
interface User {
  id: string;
  email: string;
  username: string;
  firstName: string;
  lastName: string;
  role: 'admin' | 'user';
  createdAt: string;
  updatedAt: string;
}
```

### Status Codes
- `200`: Successful GET/PUT operations
- `201`: Successful POST (user created)
- `204`: Successful DELETE operation
- `400`: Bad request (validation errors)
- `401`: Unauthorized (authentication required)
- `403`: Forbidden (insufficient permissions)
- `404`: Not found (user doesn't exist)
- `409`: Conflict (duplicate email/username)

### Pagination Response
```typescript
interface PaginatedResponse<T> {
  data: T[];
  pagination: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
  };
}
```

## Troubleshooting

### Common Issues

1. **Tests failing with 401/403 errors**
   - Verify authentication tokens are valid
   - Check if API server is running
   - Ensure correct permissions for test tokens

2. **Connection refused errors**
   - Verify API server is running on correct port
   - Check `API_BASE_URL` environment variable

3. **Tests timing out**
   - Increase timeout in Jest configuration
   - Check if API server is responding slowly
   - Verify database connectivity

4. **Clean up issues**
   - Ensure test cleanup is running properly
   - Check if delete operations are working
   - Verify database state between test runs

### Debug Mode

Run tests with debug output:
```bash
DEBUG=* npm test
```

Run specific test with verbose output:
```bash
npm test user-crud.test.ts -- --verbose
```

## Contributing

When adding new tests:

1. Follow existing naming conventions
2. Include proper cleanup in `afterEach`/`afterAll` hooks
3. Add appropriate error handling
4. Update this README if adding new test categories
5. Ensure tests are isolated and don't depend on each other

## Related Issues

- Issue #20: API specification (blocks this implementation)
- Issue #21: Backend implementation (can work in parallel)
- Issue #22: Frontend implementation (can work in parallel)

## Performance Benchmarks

Target performance metrics:
- GET /api/users: < 2 seconds
- POST /api/users: < 3 seconds  
- GET /api/users/:id: < 1.5 seconds
- PUT /api/users/:id: < 2 seconds
- DELETE /api/users/:id: < 1 second

Load testing targets:
- 20 concurrent users sustained for 5 minutes
- 95th percentile response time < 5 seconds
- Error rate < 1%