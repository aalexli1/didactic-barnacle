import { ApiClient } from '../utils/api-client';
import { User } from '../types/test-config';

describe('User CRUD Operations', () => {
  let apiClient: ApiClient;
  let adminToken: string;
  let userToken: string;
  let createdUserId: string;

  beforeAll(async () => {
    apiClient = new ApiClient();
    adminToken = await apiClient.authenticateAsAdmin();
    userToken = await apiClient.authenticateAsUser();
  });

  afterEach(async () => {
    // Clean up created user if exists
    if (createdUserId) {
      try {
        await apiClient.deleteUser(createdUserId, adminToken);
      } catch (error) {
        // Ignore cleanup errors
      }
      createdUserId = '';
    }
  });

  describe('Create User (POST /api/users)', () => {
    it('should create a new user with valid data', async () => {
      const userData: Partial<User> = {
        email: 'test@example.com',
        username: 'testuser',
        firstName: 'Test',
        lastName: 'User',
        role: 'user'
      };

      const response = await apiClient.createUser(userData, adminToken);

      expect(response.status).toBe(201);
      expect(response.body).toMatchObject({
        email: userData.email,
        username: userData.username,
        firstName: userData.firstName,
        lastName: userData.lastName,
        role: userData.role
      });
      expect(response.body.id).toBeDefined();
      expect(response.body.createdAt).toBeDefined();
      expect(response.body.updatedAt).toBeDefined();

      createdUserId = response.body.id;
    });

    it('should return 400 for missing required fields', async () => {
      const invalidUserData = {
        email: 'test@example.com'
        // Missing username, firstName, lastName
      };

      const response = await apiClient.createUser(invalidUserData, adminToken);

      expect(response.status).toBe(400);
      expect(response.body.error).toBeDefined();
      expect(response.body.message).toContain('required');
    });

    it('should return 409 for duplicate email', async () => {
      const userData: Partial<User> = {
        email: 'duplicate@example.com',
        username: 'user1',
        firstName: 'Test',
        lastName: 'User'
      };

      // Create first user
      const firstResponse = await apiClient.createUser(userData, adminToken);
      expect(firstResponse.status).toBe(201);
      createdUserId = firstResponse.body.id;

      // Try to create second user with same email
      const duplicateData = { ...userData, username: 'user2' };
      const response = await apiClient.createUser(duplicateData, adminToken);

      expect(response.status).toBe(409);
      expect(response.body.error).toBeDefined();
      expect(response.body.message).toContain('email');
    });
  });

  describe('Read Users (GET /api/users)', () => {
    beforeEach(async () => {
      // Create a test user
      const userData: Partial<User> = {
        email: 'read-test@example.com',
        username: 'readtest',
        firstName: 'Read',
        lastName: 'Test'
      };

      const response = await apiClient.createUser(userData, adminToken);
      createdUserId = response.body.id;
    });

    it('should get all users with admin token', async () => {
      const response = await apiClient.getUsers(adminToken);

      expect(response.status).toBe(200);
      expect(Array.isArray(response.body.data)).toBe(true);
      expect(response.body.pagination).toBeDefined();
      expect(response.body.pagination.total).toBeGreaterThan(0);
    });

    it('should get user by ID', async () => {
      const response = await apiClient.getUserById(createdUserId, adminToken);

      expect(response.status).toBe(200);
      expect(response.body.id).toBe(createdUserId);
      expect(response.body.email).toBe('read-test@example.com');
      expect(response.body.username).toBe('readtest');
    });

    it('should return 404 for non-existent user', async () => {
      const fakeId = '999999';
      const response = await apiClient.getUserById(fakeId, adminToken);

      expect(response.status).toBe(404);
      expect(response.body.error).toBeDefined();
      expect(response.body.message).toContain('not found');
    });

    it('should support pagination', async () => {
      const response = await apiClient.getUsers(adminToken, { page: 1, limit: 5 });

      expect(response.status).toBe(200);
      expect(response.body.data.length).toBeLessThanOrEqual(5);
      expect(response.body.pagination.page).toBe(1);
      expect(response.body.pagination.limit).toBe(5);
    });
  });

  describe('Update User (PUT /api/users/:id)', () => {
    beforeEach(async () => {
      // Create a test user
      const userData: Partial<User> = {
        email: 'update-test@example.com',
        username: 'updatetest',
        firstName: 'Update',
        lastName: 'Test'
      };

      const response = await apiClient.createUser(userData, adminToken);
      createdUserId = response.body.id;
    });

    it('should update user with valid data', async () => {
      const updateData = {
        firstName: 'Updated',
        lastName: 'Name'
      };

      const response = await apiClient.updateUser(createdUserId, updateData, adminToken);

      expect(response.status).toBe(200);
      expect(response.body.firstName).toBe('Updated');
      expect(response.body.lastName).toBe('Name');
      expect(response.body.email).toBe('update-test@example.com'); // Should remain unchanged
      expect(response.body.updatedAt).toBeDefined();
    });

    it('should return 404 for non-existent user', async () => {
      const fakeId = '999999';
      const updateData = { firstName: 'Updated' };

      const response = await apiClient.updateUser(fakeId, updateData, adminToken);

      expect(response.status).toBe(404);
      expect(response.body.error).toBeDefined();
    });

    it('should return 400 for invalid update data', async () => {
      const invalidData = {
        email: 'invalid-email' // Invalid email format
      };

      const response = await apiClient.updateUser(createdUserId, invalidData, adminToken);

      expect(response.status).toBe(400);
      expect(response.body.error).toBeDefined();
      expect(response.body.message).toContain('email');
    });
  });

  describe('Delete User (DELETE /api/users/:id)', () => {
    beforeEach(async () => {
      // Create a test user
      const userData: Partial<User> = {
        email: 'delete-test@example.com',
        username: 'deletetest',
        firstName: 'Delete',
        lastName: 'Test'
      };

      const response = await apiClient.createUser(userData, adminToken);
      createdUserId = response.body.id;
    });

    it('should delete user successfully', async () => {
      const response = await apiClient.deleteUser(createdUserId, adminToken);

      expect(response.status).toBe(204);

      // Verify user is deleted
      const getResponse = await apiClient.getUserById(createdUserId, adminToken);
      expect(getResponse.status).toBe(404);

      createdUserId = ''; // Reset so cleanup doesn't try to delete again
    });

    it('should return 404 for non-existent user', async () => {
      const fakeId = '999999';
      const response = await apiClient.deleteUser(fakeId, adminToken);

      expect(response.status).toBe(404);
      expect(response.body.error).toBeDefined();
    });
  });
});