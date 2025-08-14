import { UserModel } from '../../models/user';
import { pool } from '../../config/database';
import { CreateUserRequest, UpdateUserRequest, UserFilters } from '../../types/user';
import bcrypt from 'bcryptjs';

// Mock the database pool
jest.mock('../../config/database', () => ({
  pool: {
    query: jest.fn(),
  },
}));

// Mock bcrypt
jest.mock('bcryptjs', () => ({
  hash: jest.fn(),
}));

// Mock uuid
jest.mock('uuid', () => ({
  v4: jest.fn(() => 'mock-uuid-123'),
}));

const mockPool = pool as any;
const mockBcrypt = bcrypt as any;

describe('UserModel', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('create', () => {
    const mockUserData: CreateUserRequest = {
      username: 'testuser',
      email: 'test@example.com',
      firstName: 'Test',
      lastName: 'User',
      role: 'user',
      password: 'password123',
    };

    it('should create a user successfully', async () => {
      const mockHashedPassword = 'hashed-password';
      const mockDbResult = {
        rows: [{
          id: 'mock-uuid-123',
          username: 'testuser',
          email: 'test@example.com',
          first_name: 'Test',
          last_name: 'User',
          role: 'user',
          status: 'active',
          created_at: new Date('2023-01-01T00:00:00.000Z'),
          updated_at: new Date('2023-01-01T00:00:00.000Z'),
        }],
      };

      mockBcrypt.hash.mockResolvedValue(mockHashedPassword);
      mockPool.query.mockResolvedValue(mockDbResult);

      const result = await UserModel.create(mockUserData);

      expect(bcrypt.hash).toHaveBeenCalledWith('password123', 12);
      expect(mockPool.query).toHaveBeenCalledWith(
        expect.stringContaining('INSERT INTO users'),
        ['mock-uuid-123', 'testuser', 'test@example.com', 'Test', 'User', mockHashedPassword, 'user', 'active']
      );
      expect(result).toEqual({
        id: 'mock-uuid-123',
        username: 'testuser',
        email: 'test@example.com',
        firstName: 'Test',
        lastName: 'User',
        role: 'user',
        status: 'active',
        createdAt: '2023-01-01T00:00:00.000Z',
        updatedAt: '2023-01-01T00:00:00.000Z',
      });
    });

    it('should throw error for duplicate email', async () => {
      const mockHashedPassword = 'hashed-password';
      const duplicateError = new Error('Unique constraint violation') as any;
      duplicateError.code = '23505';

      mockBcrypt.hash.mockResolvedValue(mockHashedPassword);
      mockPool.query.mockRejectedValue(duplicateError);

      await expect(UserModel.create(mockUserData)).rejects.toThrow('Email already exists');
    });

    it('should rethrow other database errors', async () => {
      const mockHashedPassword = 'hashed-password';
      const dbError = new Error('Database connection failed');

      mockBcrypt.hash.mockResolvedValue(mockHashedPassword);
      mockPool.query.mockRejectedValue(dbError);

      await expect(UserModel.create(mockUserData)).rejects.toThrow('Database connection failed');
    });
  });

  describe('findAll', () => {
    const mockUsersDbResult = {
      rows: [
        {
          id: 'user-1',
          username: 'userone',
          email: 'user1@example.com',
          first_name: 'User',
          last_name: 'One',
          role: 'user',
          status: 'active',
          created_at: new Date('2023-01-01T00:00:00.000Z'),
          updated_at: new Date('2023-01-01T00:00:00.000Z'),
        },
        {
          id: 'user-2',
          username: 'usertwo',
          email: 'user2@example.com',
          first_name: 'User',
          last_name: 'Two',
          role: 'admin',
          status: 'active',
          created_at: new Date('2023-01-02T00:00:00.000Z'),
          updated_at: new Date('2023-01-02T00:00:00.000Z'),
        },
      ],
    };

    const mockCountResult = {
      rows: [{ count: '2' }],
    };

    it('should return all users with default pagination', async () => {
      mockPool.query
        .mockResolvedValueOnce(mockCountResult)
        .mockResolvedValueOnce(mockUsersDbResult);

      const result = await UserModel.findAll();

      expect(mockPool.query).toHaveBeenCalledTimes(2);
      expect(mockPool.query).toHaveBeenNthCalledWith(1, 'SELECT COUNT(*) FROM users WHERE 1=1', []);
      expect(mockPool.query).toHaveBeenNthCalledWith(
        2,
        expect.stringContaining('SELECT id, username, email, first_name, last_name, role, status, created_at, updated_at'),
        [10, 0]
      );

      expect(result.total).toBe(2);
      expect(result.users).toHaveLength(2);
      expect(result.users[0]).toEqual({
        id: 'user-1',
        username: 'userone',
        email: 'user1@example.com',
        firstName: 'User',
        lastName: 'One',
        role: 'user',
        status: 'active',
        createdAt: '2023-01-01T00:00:00.000Z',
        updatedAt: '2023-01-01T00:00:00.000Z',
      });
    });

    it('should filter users by search term', async () => {
      const filters: UserFilters = { search: 'User One' };

      mockPool.query
        .mockResolvedValueOnce(mockCountResult)
        .mockResolvedValueOnce(mockUsersDbResult);

      await UserModel.findAll(filters);

      expect(mockPool.query).toHaveBeenNthCalledWith(
        1,
        'SELECT COUNT(*) FROM users WHERE 1=1 AND (username ILIKE $1 OR email ILIKE $1 OR first_name ILIKE $1 OR last_name ILIKE $1)',
        ['%User One%']
      );
    });

    it('should filter users by role', async () => {
      const filters: UserFilters = { role: 'admin' };

      mockPool.query
        .mockResolvedValueOnce(mockCountResult)
        .mockResolvedValueOnce(mockUsersDbResult);

      await UserModel.findAll(filters);

      expect(mockPool.query).toHaveBeenNthCalledWith(
        1,
        'SELECT COUNT(*) FROM users WHERE 1=1 AND role = $1',
        ['admin']
      );
    });

    it('should filter users by status', async () => {
      const filters: UserFilters = { status: 'inactive' };

      mockPool.query
        .mockResolvedValueOnce(mockCountResult)
        .mockResolvedValueOnce(mockUsersDbResult);

      await UserModel.findAll(filters);

      expect(mockPool.query).toHaveBeenNthCalledWith(
        1,
        'SELECT COUNT(*) FROM users WHERE 1=1 AND status = $1',
        ['inactive']
      );
    });

    it('should handle custom pagination', async () => {
      const filters: UserFilters = { page: 2, limit: 5 };

      mockPool.query
        .mockResolvedValueOnce(mockCountResult)
        .mockResolvedValueOnce(mockUsersDbResult);

      await UserModel.findAll(filters);

      expect(mockPool.query).toHaveBeenNthCalledWith(
        2,
        expect.stringContaining('LIMIT $1 OFFSET $2'),
        [5, 5] // limit 5, offset 5 (page 2)
      );
    });

    it('should combine multiple filters', async () => {
      const filters: UserFilters = {
        search: 'test',
        role: 'user',
        status: 'active',
        page: 1,
        limit: 20,
      };

      mockPool.query
        .mockResolvedValueOnce(mockCountResult)
        .mockResolvedValueOnce(mockUsersDbResult);

      await UserModel.findAll(filters);

      expect(mockPool.query).toHaveBeenNthCalledWith(
        1,
        'SELECT COUNT(*) FROM users WHERE 1=1 AND (username ILIKE $1 OR email ILIKE $1 OR first_name ILIKE $1 OR last_name ILIKE $1) AND role = $2 AND status = $3',
        ['%test%', 'user', 'active']
      );
    });
  });

  describe('findById', () => {
    it('should return user when found', async () => {
      const mockDbResult = {
        rows: [{
          id: 'user-123',
          username: 'testuser',
          email: 'test@example.com',
          first_name: 'Test',
          last_name: 'User',
          role: 'user',
          status: 'active',
          created_at: new Date('2023-01-01T00:00:00.000Z'),
          updated_at: new Date('2023-01-01T00:00:00.000Z'),
        }],
      };

      mockPool.query.mockResolvedValue(mockDbResult);

      const result = await UserModel.findById('user-123');

      expect(mockPool.query).toHaveBeenCalledWith(
        expect.stringContaining('SELECT id, username, email, first_name, last_name, role, status, created_at, updated_at'),
        ['user-123']
      );
      expect(result).toEqual({
        id: 'user-123',
        username: 'testuser',
        email: 'test@example.com',
        firstName: 'Test',
        lastName: 'User',
        role: 'user',
        status: 'active',
        createdAt: '2023-01-01T00:00:00.000Z',
        updatedAt: '2023-01-01T00:00:00.000Z',
      });
    });

    it('should return null when user not found', async () => {
      const mockDbResult = { rows: [] };

      mockPool.query.mockResolvedValue(mockDbResult);

      const result = await UserModel.findById('nonexistent-id');

      expect(result).toBeNull();
    });
  });

  describe('update', () => {
    const mockExistingUser = {
      id: 'user-123',
      username: 'testuser',
      email: 'test@example.com',
      firstName: 'Test',
      lastName: 'User',
      role: 'user' as const,
      status: 'active' as const,
      createdAt: '2023-01-01T00:00:00.000Z',
      updatedAt: '2023-01-01T00:00:00.000Z',
    };

    beforeEach(() => {
      // Mock findById
      jest.spyOn(UserModel, 'findById').mockResolvedValue(mockExistingUser);
    });

    it('should update user successfully', async () => {
      const updateData: UpdateUserRequest = {
        firstName: 'Updated',
        lastName: 'Name',
        email: 'updated@example.com',
      };

      const mockDbResult = {
        rows: [{
          id: 'user-123',
          username: 'testuser',
          email: 'updated@example.com',
          first_name: 'Updated',
          last_name: 'Name',
          role: 'user',
          status: 'active',
          created_at: new Date('2023-01-01T00:00:00.000Z'),
          updated_at: new Date('2023-01-01T12:00:00.000Z'),
        }],
      };

      mockPool.query.mockResolvedValue(mockDbResult);

      const result = await UserModel.update('user-123', updateData);

      expect(mockPool.query).toHaveBeenCalledWith(
        expect.stringContaining('UPDATE users'),
        ['updated@example.com', 'Updated', 'Name', 'user-123']
      );
      expect(result?.firstName).toBe('Updated');
      expect(result?.lastName).toBe('Name');
      expect(result?.email).toBe('updated@example.com');
    });

    it('should return null for nonexistent user', async () => {
      jest.spyOn(UserModel, 'findById').mockResolvedValue(null);

      const result = await UserModel.update('nonexistent-id', { firstName: 'New Name' });

      expect(result).toBeNull();
    });

    it('should return existing user if no updates provided', async () => {
      const result = await UserModel.update('user-123', {});

      expect(result).toEqual(mockExistingUser);
      expect(mockPool.query).not.toHaveBeenCalled();
    });

    it('should handle duplicate email error', async () => {
      const updateData: UpdateUserRequest = { email: 'duplicate@example.com' };
      const duplicateError = new Error('Unique constraint violation') as any;
      duplicateError.code = '23505';

      mockPool.query.mockRejectedValue(duplicateError);

      await expect(UserModel.update('user-123', updateData)).rejects.toThrow('Email already exists');
    });

    it('should update only provided fields', async () => {
      const updateData: UpdateUserRequest = { status: 'inactive' };

      const mockDbResult = {
        rows: [{
          id: mockExistingUser.id,
          username: mockExistingUser.username,
          email: mockExistingUser.email,
          first_name: mockExistingUser.firstName,
          last_name: mockExistingUser.lastName,
          role: mockExistingUser.role,
          status: 'inactive',
          created_at: new Date('2023-01-01T00:00:00.000Z'),
          updated_at: new Date('2023-01-01T12:00:00.000Z'),
        }],
      };

      mockPool.query.mockResolvedValue(mockDbResult);

      await UserModel.update('user-123', updateData);

      expect(mockPool.query).toHaveBeenCalledWith(
        expect.stringContaining('status = $1'),
        ['inactive', 'user-123']
      );
    });
  });

  describe('delete', () => {
    it('should delete user successfully', async () => {
      const mockDbResult = { rowCount: 1 };

      mockPool.query.mockResolvedValue(mockDbResult);

      const result = await UserModel.delete('user-123');

      expect(mockPool.query).toHaveBeenCalledWith(
        'DELETE FROM users WHERE id = $1',
        ['user-123']
      );
      expect(result).toBe(true);
    });

    it('should return false when user not found', async () => {
      const mockDbResult = { rowCount: 0 };

      mockPool.query.mockResolvedValue(mockDbResult);

      const result = await UserModel.delete('nonexistent-id');

      expect(result).toBe(false);
    });
  });
});