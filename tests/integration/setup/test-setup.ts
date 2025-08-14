import { TestConfig } from '../types/test-config';

// Global test configuration
export const testConfig: TestConfig = {
  baseUrl: process.env.API_BASE_URL || 'http://localhost:3000',
  timeout: 30000,
  retries: 3,
  auth: {
    adminToken: process.env.ADMIN_TOKEN || 'test-admin-token',
    userToken: process.env.USER_TOKEN || 'test-user-token'
  }
};

// Global test setup
beforeAll(async () => {
  console.log('Setting up integration tests...');
  // Add any global setup logic here
});

afterAll(async () => {
  console.log('Cleaning up after integration tests...');
  // Add any global cleanup logic here
});

// Global error handler for unhandled promises
process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise, 'reason:', reason);
});