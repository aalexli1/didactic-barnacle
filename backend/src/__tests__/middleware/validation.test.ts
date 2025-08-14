import { Request, Response, NextFunction } from 'express';
import { validateCreateUser, validateUpdateUser, validateUserFilters } from '../../middleware/validation';

describe('Validation Middleware', () => {
  let mockRequest: Partial<Request>;
  let mockResponse: Partial<Response>;
  let nextFunction: NextFunction;

  beforeEach(() => {
    mockRequest = {};
    mockResponse = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn().mockReturnThis(),
    };
    nextFunction = jest.fn();
  });

  describe('validateCreateUser', () => {
    it('should pass validation for valid user data', () => {
      mockRequest.body = {
        username: 'testuser',
        email: 'test@example.com',
        firstName: 'Test',
        lastName: 'User',
        role: 'user',
        password: 'password123',
      };

      validateCreateUser(mockRequest as Request, mockResponse as Response, nextFunction);

      expect(nextFunction).toHaveBeenCalled();
      expect(mockResponse.status).not.toHaveBeenCalled();
    });

    it('should fail validation for missing username', () => {
      mockRequest.body = {
        email: 'test@example.com',
        firstName: 'Test',
        lastName: 'User',
        role: 'user',
        password: 'password123',
      };

      validateCreateUser(mockRequest as Request, mockResponse as Response, nextFunction);

      expect(mockResponse.status).toHaveBeenCalledWith(400);
      expect(mockResponse.json).toHaveBeenCalledWith(
        expect.objectContaining({
          error: 'Validation Error',
          message: expect.stringContaining('username'),
        })
      );
      expect(nextFunction).not.toHaveBeenCalled();
    });

    it('should fail validation for invalid email', () => {
      mockRequest.body = {
        username: 'testuser',
        email: 'invalid-email',
        firstName: 'Test',
        lastName: 'User',
        role: 'user',
        password: 'password123',
      };

      validateCreateUser(mockRequest as Request, mockResponse as Response, nextFunction);

      expect(mockResponse.status).toHaveBeenCalledWith(400);
      expect(mockResponse.json).toHaveBeenCalledWith(
        expect.objectContaining({
          error: 'Validation Error',
          message: expect.stringContaining('email'),
        })
      );
    });

    it('should fail validation for invalid role', () => {
      mockRequest.body = {
        username: 'testuser',
        email: 'test@example.com',
        firstName: 'Test',
        lastName: 'User',
        role: 'invalid-role',
        password: 'password123',
      };

      validateCreateUser(mockRequest as Request, mockResponse as Response, nextFunction);

      expect(mockResponse.status).toHaveBeenCalledWith(400);
      expect(mockResponse.json).toHaveBeenCalledWith(
        expect.objectContaining({
          error: 'Validation Error',
          message: expect.stringContaining('role'),
        })
      );
    });

    it('should fail validation for short password', () => {
      mockRequest.body = {
        username: 'testuser',
        email: 'test@example.com',
        firstName: 'Test',
        lastName: 'User',
        role: 'user',
        password: '123',
      };

      validateCreateUser(mockRequest as Request, mockResponse as Response, nextFunction);

      expect(mockResponse.status).toHaveBeenCalledWith(400);
      expect(mockResponse.json).toHaveBeenCalledWith(
        expect.objectContaining({
          error: 'Validation Error',
          message: expect.stringContaining('password'),
        })
      );
    });

    it('should trim whitespace from username', () => {
      mockRequest.body = {
        username: '  testuser  ',
        email: 'test@example.com',
        firstName: 'Test',
        lastName: 'User',
        role: 'user',
        password: 'password123',
      };

      validateCreateUser(mockRequest as Request, mockResponse as Response, nextFunction);

      expect(nextFunction).toHaveBeenCalled();
    });

    it('should fail validation for empty username after trimming', () => {
      mockRequest.body = {
        username: '   ',
        email: 'test@example.com',
        firstName: 'Test',
        lastName: 'User',
        role: 'user',
        password: 'password123',
      };

      validateCreateUser(mockRequest as Request, mockResponse as Response, nextFunction);

      expect(mockResponse.status).toHaveBeenCalledWith(400);
    });

    it('should fail validation for username too long', () => {
      mockRequest.body = {
        username: 'a'.repeat(51), // 51 characters
        email: 'test@example.com',
        firstName: 'Test',
        lastName: 'User',
        role: 'user',
        password: 'password123',
      };

      validateCreateUser(mockRequest as Request, mockResponse as Response, nextFunction);

      expect(mockResponse.status).toHaveBeenCalledWith(400);
    });
  });

  describe('validateUpdateUser', () => {
    it('should pass validation for valid update data', () => {
      mockRequest.body = {
        firstName: 'Updated',
        lastName: 'Name',
        email: 'updated@example.com',
      };

      validateUpdateUser(mockRequest as Request, mockResponse as Response, nextFunction);

      expect(nextFunction).toHaveBeenCalled();
      expect(mockResponse.status).not.toHaveBeenCalled();
    });

    it('should pass validation for partial updates', () => {
      mockRequest.body = {
        firstName: 'Updated Name',
      };

      validateUpdateUser(mockRequest as Request, mockResponse as Response, nextFunction);

      expect(nextFunction).toHaveBeenCalled();
    });

    it('should fail validation for empty body', () => {
      mockRequest.body = {};

      validateUpdateUser(mockRequest as Request, mockResponse as Response, nextFunction);

      expect(mockResponse.status).toHaveBeenCalledWith(400);
      expect(mockResponse.json).toHaveBeenCalledWith(
        expect.objectContaining({
          error: 'Validation Error',
        })
      );
    });

    it('should fail validation for invalid email in update', () => {
      mockRequest.body = {
        email: 'invalid-email',
      };

      validateUpdateUser(mockRequest as Request, mockResponse as Response, nextFunction);

      expect(mockResponse.status).toHaveBeenCalledWith(400);
    });

    it('should fail validation for invalid role in update', () => {
      mockRequest.body = {
        role: 'invalid-role',
      };

      validateUpdateUser(mockRequest as Request, mockResponse as Response, nextFunction);

      expect(mockResponse.status).toHaveBeenCalledWith(400);
    });

    it('should fail validation for invalid status in update', () => {
      mockRequest.body = {
        status: 'invalid-status',
      };

      validateUpdateUser(mockRequest as Request, mockResponse as Response, nextFunction);

      expect(mockResponse.status).toHaveBeenCalledWith(400);
    });

    it('should pass validation for valid status values', () => {
      const validStatuses = ['active', 'inactive', 'suspended'];
      
      validStatuses.forEach(status => {
        mockRequest.body = { status };
        
        validateUpdateUser(mockRequest as Request, mockResponse as Response, nextFunction);
        
        expect(nextFunction).toHaveBeenCalled();
        jest.clearAllMocks();
      });
    });

    it('should pass validation for valid role values', () => {
      const validRoles = ['admin', 'user', 'moderator'];
      
      validRoles.forEach(role => {
        mockRequest.body = { role };
        
        validateUpdateUser(mockRequest as Request, mockResponse as Response, nextFunction);
        
        expect(nextFunction).toHaveBeenCalled();
        jest.clearAllMocks();
      });
    });
  });

  describe('validateUserFilters', () => {
    it('should pass validation for valid filters', () => {
      mockRequest.query = {
        search: 'test',
        role: 'user',
        status: 'active',
        page: '1',
        limit: '10',
      };

      validateUserFilters(mockRequest as Request, mockResponse as Response, nextFunction);

      expect(nextFunction).toHaveBeenCalled();
      expect(mockResponse.status).not.toHaveBeenCalled();
    });

    it('should pass validation for empty filters', () => {
      mockRequest.query = {};

      validateUserFilters(mockRequest as Request, mockResponse as Response, nextFunction);

      expect(nextFunction).toHaveBeenCalled();
    });

    it('should fail validation for invalid page', () => {
      mockRequest.query = {
        page: 'invalid',
      };

      validateUserFilters(mockRequest as Request, mockResponse as Response, nextFunction);

      expect(mockResponse.status).toHaveBeenCalledWith(400);
    });

    it('should fail validation for page less than 1', () => {
      mockRequest.query = {
        page: '0',
      };

      validateUserFilters(mockRequest as Request, mockResponse as Response, nextFunction);

      expect(mockResponse.status).toHaveBeenCalledWith(400);
    });

    it('should fail validation for invalid limit', () => {
      mockRequest.query = {
        limit: 'invalid',
      };

      validateUserFilters(mockRequest as Request, mockResponse as Response, nextFunction);

      expect(mockResponse.status).toHaveBeenCalledWith(400);
    });

    it('should fail validation for limit exceeding maximum', () => {
      mockRequest.query = {
        limit: '101',
      };

      validateUserFilters(mockRequest as Request, mockResponse as Response, nextFunction);

      expect(mockResponse.status).toHaveBeenCalledWith(400);
    });

    it('should fail validation for limit less than 1', () => {
      mockRequest.query = {
        limit: '0',
      };

      validateUserFilters(mockRequest as Request, mockResponse as Response, nextFunction);

      expect(mockResponse.status).toHaveBeenCalledWith(400);
    });

    it('should fail validation for invalid role in filters', () => {
      mockRequest.query = {
        role: 'invalid-role',
      };

      validateUserFilters(mockRequest as Request, mockResponse as Response, nextFunction);

      expect(mockResponse.status).toHaveBeenCalledWith(400);
    });

    it('should fail validation for invalid status in filters', () => {
      mockRequest.query = {
        status: 'invalid-status',
      };

      validateUserFilters(mockRequest as Request, mockResponse as Response, nextFunction);

      expect(mockResponse.status).toHaveBeenCalledWith(400);
    });

    it('should trim search parameter', () => {
      mockRequest.query = {
        search: '  test search  ',
      };

      validateUserFilters(mockRequest as Request, mockResponse as Response, nextFunction);

      expect(nextFunction).toHaveBeenCalled();
    });
  });
});