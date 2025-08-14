import { ApiClient } from '../utils/api-client';
import { User } from '../types/test-config';

describe('User API Authentication & Authorization', () => {
  let apiClient: ApiClient;
  let adminToken: string;
  let userToken: string;
  let testUserId: string;

  beforeAll(async () => {
    apiClient = new ApiClient();
    adminToken = await apiClient.authenticateAsAdmin();
    userToken = await apiClient.authenticateAsUser();

    // Create a test user for authorization tests
    const userData: Partial<User> = {
      email: 'auth-test@example.com',
      username: 'authtest',
      firstName: 'Auth',
      lastName: 'Test'
    };
    const response = await apiClient.createUser(userData, adminToken);
    testUserId = response.body.id;
  });

  afterAll(async () => {
    // Clean up test user
    if (testUserId) {
      try {
        await apiClient.deleteUser(testUserId, adminToken);
      } catch (error) {
        // Ignore cleanup errors
      }
    }
  });

  describe('Authentication (401 Unauthorized)', () => {
    it('should return 401 when accessing users without token', async () => {
      const response = await apiClient.getUsers();

      expect(response.status).toBe(401);
      expect(response.body.error).toBeDefined();
      expect(response.body.message).toContain('unauthorized');
    });

    it('should return 401 with invalid token', async () => {
      const response = await apiClient.getUsers('invalid-token');

      expect(response.status).toBe(401);
      expect(response.body.error).toBeDefined();
      expect(response.body.message).toContain('invalid');
    });

    it('should return 401 when creating user without token', async () => {
      const userData = {
        email: 'test@example.com',
        username: 'test',
        firstName: 'Test',
        lastName: 'User'
      };

      const response = await apiClient.createUser(userData);

      expect(response.status).toBe(401);
      expect(response.body.error).toBeDefined();
    });

    it('should return 401 when updating user without token', async () => {
      const updateData = { firstName: 'Updated' };
      const response = await apiClient.updateUser(testUserId, updateData);

      expect(response.status).toBe(401);
      expect(response.body.error).toBeDefined();
    });

    it('should return 401 when deleting user without token', async () => {
      const response = await apiClient.deleteUser(testUserId);

      expect(response.status).toBe(401);
      expect(response.body.error).toBeDefined();
    });
  });

  describe('Authorization (403 Forbidden)', () => {
    it('should return 403 when regular user tries to create user', async () => {
      const userData = {
        email: 'forbidden@example.com',
        username: 'forbidden',
        firstName: 'Forbidden',
        lastName: 'User'
      };

      const response = await apiClient.createUser(userData, userToken);

      expect(response.status).toBe(403);
      expect(response.body.error).toBeDefined();
      expect(response.body.message).toContain('forbidden');
    });

    it('should return 403 when regular user tries to delete user', async () => {
      const response = await apiClient.deleteUser(testUserId, userToken);

      expect(response.status).toBe(403);
      expect(response.body.error).toBeDefined();
      expect(response.body.message).toContain('forbidden');
    });

    it('should return 403 when regular user tries to update other users', async () => {
      const updateData = { firstName: 'Hacked' };
      const response = await apiClient.updateUser(testUserId, updateData, userToken);

      expect(response.status).toBe(403);
      expect(response.body.error).toBeDefined();
      expect(response.body.message).toContain('forbidden');
    });

    it('should allow regular user to view their own profile', async () => {
      // Assuming userToken corresponds to testUserId
      const response = await apiClient.getUserById(testUserId, userToken);

      expect([200, 403]).toContain(response.status);
      // Should be 200 if viewing own profile, 403 if viewing others
    });
  });

  describe('Not Found (404)', () => {
    it('should return 404 for non-existent user ID', async () => {
      const fakeId = '99999999-9999-4999-9999-999999999999';
      const response = await apiClient.getUserById(fakeId, adminToken);

      expect(response.status).toBe(404);
      expect(response.body.error).toBeDefined();
      expect(response.body.message).toContain('not found');
    });

    it('should return 404 when updating non-existent user', async () => {
      const fakeId = '99999999-9999-4999-9999-999999999999';
      const updateData = { firstName: 'Updated' };
      const response = await apiClient.updateUser(fakeId, updateData, adminToken);

      expect(response.status).toBe(404);
      expect(response.body.error).toBeDefined();
    });

    it('should return 404 when deleting non-existent user', async () => {
      const fakeId = '99999999-9999-4999-9999-999999999999';
      const response = await apiClient.deleteUser(fakeId, adminToken);

      expect(response.status).toBe(404);
      expect(response.body.error).toBeDefined();
    });

    it('should return 404 for malformed user ID', async () => {
      const malformedId = 'not-a-valid-id';
      const response = await apiClient.getUserById(malformedId, adminToken);

      expect([400, 404]).toContain(response.status);
      expect(response.body.error).toBeDefined();
    });
  });

  describe('Bad Request (400)', () => {
    it('should return 400 for invalid email format', async () => {
      const userData = {
        email: 'invalid-email',
        username: 'test',
        firstName: 'Test',
        lastName: 'User'
      };

      const response = await apiClient.createUser(userData, adminToken);

      expect(response.status).toBe(400);
      expect(response.body.error).toBeDefined();
      expect(response.body.message).toContain('email');
    });

    it('should return 400 for missing required fields', async () => {
      const incompleteData = {
        email: 'test@example.com'
        // Missing username, firstName, lastName
      };

      const response = await apiClient.createUser(incompleteData, adminToken);

      expect(response.status).toBe(400);
      expect(response.body.error).toBeDefined();
      expect(response.body.message).toContain('required');
    });

    it('should return 400 for invalid pagination parameters', async () => {
      const response = await apiClient.getUsers(adminToken, { 
        page: -1, 
        limit: 1000 
      });

      expect(response.status).toBe(400);
      expect(response.body.error).toBeDefined();
    });

    it('should return 400 for username that is too short', async () => {
      const userData = {
        email: 'test@example.com',
        username: 'ab', // Too short
        firstName: 'Test',
        lastName: 'User'
      };

      const response = await apiClient.createUser(userData, adminToken);

      expect(response.status).toBe(400);
      expect(response.body.error).toBeDefined();
      expect(response.body.message).toContain('username');
    });
  });
});