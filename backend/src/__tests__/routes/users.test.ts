import request from 'supertest';
import express from 'express';
import userRoutes from '../../routes/users';
import { UserModel } from '../../models/user';

// Mock the UserModel
jest.mock('../../models/user');

const mockUserModel = UserModel as jest.Mocked<typeof UserModel>;

const app = express();
app.use(express.json());
app.use('/api/v1/users', userRoutes);

describe('User Routes', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('GET /api/v1/users', () => {
    const mockUsers = [
      {
        id: 'user-1',
        username: 'userone',
        firstName: 'User',
        lastName: 'One',
        email: 'user1@example.com',
        role: 'user' as const,
        status: 'active' as const,
        createdAt: '2023-01-01T00:00:00.000Z',
        updatedAt: '2023-01-01T00:00:00.000Z',
      },
      {
        id: 'user-2',
        username: 'usertwo',
        firstName: 'User',
        lastName: 'Two',
        email: 'user2@example.com',
        role: 'admin' as const,
        status: 'active' as const,
        createdAt: '2023-01-02T00:00:00.000Z',
        updatedAt: '2023-01-02T00:00:00.000Z',
      },
    ];

    it('should return users with pagination info', async () => {
      mockUserModel.findAll.mockResolvedValue({
        users: mockUsers,
        total: 2,
      });

      const response = await request(app)
        .get('/api/v1/users')
        .expect(200);

      expect(response.body).toEqual({
        users: mockUsers,
        total: 2,
        page: 1,
        limit: 10,
        totalPages: 1,
      });
      expect(mockUserModel.findAll).toHaveBeenCalledWith({
        search: undefined,
        role: undefined,
        status: undefined,
        page: undefined,
        limit: undefined,
      });
    });

    it('should handle query parameters', async () => {
      mockUserModel.findAll.mockResolvedValue({
        users: [mockUsers[0]],
        total: 1,
      });

      const response = await request(app)
        .get('/api/v1/users')
        .query({
          search: 'User One',
          role: 'user',
          status: 'active',
          page: '2',
          limit: '5',
        })
        .expect(200);

      expect(mockUserModel.findAll).toHaveBeenCalledWith({
        search: 'User One',
        role: 'user',
        status: 'active',
        page: 2,
        limit: 5,
      });
      expect(response.body.page).toBe(2);
      expect(response.body.limit).toBe(5);
    });

    it('should handle validation errors for invalid query parameters', async () => {
      const response = await request(app)
        .get('/api/v1/users')
        .query({
          page: 'invalid',
          limit: '101', // Exceeds max limit
        })
        .expect(400);

      expect(response.body.error).toBe('Validation Error');
    });

    it('should handle database errors', async () => {
      mockUserModel.findAll.mockRejectedValue(new Error('Database error'));

      await request(app)
        .get('/api/v1/users')
        .expect(500);
    });
  });

  describe('GET /api/v1/users/:id', () => {
    const mockUser = {
      id: 'user-123',
      username: 'testuser',
      firstName: 'Test',
      lastName: 'User',
      email: 'test@example.com',
      role: 'user' as const,
      status: 'active' as const,
      createdAt: '2023-01-01T00:00:00.000Z',
      updatedAt: '2023-01-01T00:00:00.000Z',
    };

    it('should return user when found', async () => {
      mockUserModel.findById.mockResolvedValue(mockUser);

      const response = await request(app)
        .get('/api/v1/users/user-123')
        .expect(200);

      expect(response.body).toEqual(mockUser);
      expect(mockUserModel.findById).toHaveBeenCalledWith('user-123');
    });

    it('should return 404 when user not found', async () => {
      mockUserModel.findById.mockResolvedValue(null);

      const response = await request(app)
        .get('/api/v1/users/nonexistent-id')
        .expect(404);

      expect(response.body).toEqual({
        error: 'Not Found',
        message: 'User not found',
      });
    });

    it('should handle database errors', async () => {
      mockUserModel.findById.mockRejectedValue(new Error('Database error'));

      await request(app)
        .get('/api/v1/users/user-123')
        .expect(500);
    });
  });

  describe('POST /api/v1/users', () => {
    const validUserData = {
      username: 'newuser',
      firstName: 'New',
      lastName: 'User',
      email: 'new@example.com',
      role: 'user',
      password: 'password123',
    };

    const mockCreatedUser = {
      id: 'new-user-id',
      username: 'newuser',
      firstName: 'New',
      lastName: 'User',
      email: 'new@example.com',
      role: 'user' as const,
      status: 'active' as const,
      createdAt: '2023-01-01T00:00:00.000Z',
      updatedAt: '2023-01-01T00:00:00.000Z',
    };

    it('should create user successfully', async () => {
      mockUserModel.create.mockResolvedValue(mockCreatedUser);

      const response = await request(app)
        .post('/api/v1/users')
        .send(validUserData)
        .expect(201);

      expect(response.body).toEqual(mockCreatedUser);
      expect(mockUserModel.create).toHaveBeenCalledWith(validUserData);
    });

    it('should validate required fields', async () => {
      const response = await request(app)
        .post('/api/v1/users')
        .send({
          name: 'Test User',
          // Missing required fields
        })
        .expect(400);

      expect(response.body.error).toBe('Validation Error');
      expect(mockUserModel.create).not.toHaveBeenCalled();
    });

    it('should validate email format', async () => {
      const response = await request(app)
        .post('/api/v1/users')
        .send({
          ...validUserData,
          email: 'invalid-email',
        })
        .expect(400);

      expect(response.body.error).toBe('Validation Error');
    });

    it('should validate password length', async () => {
      const response = await request(app)
        .post('/api/v1/users')
        .send({
          ...validUserData,
          password: '123', // Too short
        })
        .expect(400);

      expect(response.body.error).toBe('Validation Error');
    });

    it('should validate role values', async () => {
      const response = await request(app)
        .post('/api/v1/users')
        .send({
          ...validUserData,
          role: 'invalid-role',
        })
        .expect(400);

      expect(response.body.error).toBe('Validation Error');
    });

    it('should handle duplicate email error', async () => {
      mockUserModel.create.mockRejectedValue(new Error('Email already exists'));

      await request(app)
        .post('/api/v1/users')
        .send(validUserData)
        .expect(500);
    });

    it('should handle database errors', async () => {
      mockUserModel.create.mockRejectedValue(new Error('Database error'));

      await request(app)
        .post('/api/v1/users')
        .send(validUserData)
        .expect(500);
    });
  });

  describe('PUT /api/v1/users/:id', () => {
    const validUpdateData = {
      firstName: 'Updated',
      lastName: 'Name',
      email: 'updated@example.com',
    };

    const mockUpdatedUser = {
      id: 'user-123',
      username: 'testuser',
      firstName: 'Updated',
      lastName: 'Name',
      email: 'updated@example.com',
      role: 'user' as const,
      status: 'active' as const,
      createdAt: '2023-01-01T00:00:00.000Z',
      updatedAt: '2023-01-01T12:00:00.000Z',
    };

    it('should update user successfully', async () => {
      mockUserModel.update.mockResolvedValue(mockUpdatedUser);

      const response = await request(app)
        .put('/api/v1/users/user-123')
        .send(validUpdateData)
        .expect(200);

      expect(response.body).toEqual(mockUpdatedUser);
      expect(mockUserModel.update).toHaveBeenCalledWith('user-123', validUpdateData);
    });

    it('should return 404 when user not found', async () => {
      mockUserModel.update.mockResolvedValue(null);

      const response = await request(app)
        .put('/api/v1/users/nonexistent-id')
        .send(validUpdateData)
        .expect(404);

      expect(response.body).toEqual({
        error: 'Not Found',
        message: 'User not found',
      });
    });

    it('should require at least one field to update', async () => {
      const response = await request(app)
        .put('/api/v1/users/user-123')
        .send({})
        .expect(400);

      expect(response.body.error).toBe('Validation Error');
      expect(mockUserModel.update).not.toHaveBeenCalled();
    });

    it('should validate email format in updates', async () => {
      const response = await request(app)
        .put('/api/v1/users/user-123')
        .send({
          email: 'invalid-email',
        })
        .expect(400);

      expect(response.body.error).toBe('Validation Error');
    });

    it('should validate role values in updates', async () => {
      const response = await request(app)
        .put('/api/v1/users/user-123')
        .send({
          role: 'invalid-role',
        })
        .expect(400);

      expect(response.body.error).toBe('Validation Error');
    });

    it('should validate status values in updates', async () => {
      const response = await request(app)
        .put('/api/v1/users/user-123')
        .send({
          status: 'invalid-status',
        })
        .expect(400);

      expect(response.body.error).toBe('Validation Error');
    });

    it('should handle duplicate email error', async () => {
      mockUserModel.update.mockRejectedValue(new Error('Email already exists'));

      await request(app)
        .put('/api/v1/users/user-123')
        .send({ email: 'duplicate@example.com' })
        .expect(500);
    });

    it('should handle database errors', async () => {
      mockUserModel.update.mockRejectedValue(new Error('Database error'));

      await request(app)
        .put('/api/v1/users/user-123')
        .send(validUpdateData)
        .expect(500);
    });
  });

  describe('DELETE /api/v1/users/:id', () => {
    it('should delete user successfully', async () => {
      mockUserModel.delete.mockResolvedValue(true);

      await request(app)
        .delete('/api/v1/users/user-123')
        .expect(204);

      expect(mockUserModel.delete).toHaveBeenCalledWith('user-123');
    });

    it('should return 404 when user not found', async () => {
      mockUserModel.delete.mockResolvedValue(false);

      const response = await request(app)
        .delete('/api/v1/users/nonexistent-id')
        .expect(404);

      expect(response.body).toEqual({
        error: 'Not Found',
        message: 'User not found',
      });
    });

    it('should handle database errors', async () => {
      mockUserModel.delete.mockRejectedValue(new Error('Database error'));

      await request(app)
        .delete('/api/v1/users/user-123')
        .expect(500);
    });
  });
});