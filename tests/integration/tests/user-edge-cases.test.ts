import { ApiClient } from '../utils/api-client';
import { User } from '../types/test-config';

describe('User API Edge Cases', () => {
  let apiClient: ApiClient;
  let adminToken: string;
  let createdUserIds: string[] = [];

  beforeAll(async () => {
    apiClient = new ApiClient();
    adminToken = await apiClient.authenticateAsAdmin();
  });

  afterEach(async () => {
    // Clean up all created users
    for (const userId of createdUserIds) {
      try {
        await apiClient.deleteUser(userId, adminToken);
      } catch (error) {
        // Ignore cleanup errors
      }
    }
    createdUserIds = [];
  });

  describe('Empty and Null Fields', () => {
    it('should handle empty string in required fields', async () => {
      const userData = {
        email: '',
        username: '',
        firstName: '',
        lastName: ''
      };

      const response = await apiClient.createUser(userData, adminToken);

      expect(response.status).toBe(400);
      expect(response.body.error).toBeDefined();
      expect(response.body.message).toMatch(/required|empty|blank/i);
    });

    it('should handle null values in required fields', async () => {
      const userData = {
        email: null as any,
        username: null as any,
        firstName: null as any,
        lastName: null as any
      };

      const response = await apiClient.createUser(userData, adminToken);

      expect(response.status).toBe(400);
      expect(response.body.error).toBeDefined();
    });

    it('should handle undefined values in required fields', async () => {
      const userData = {
        email: undefined,
        username: undefined,
        firstName: undefined,
        lastName: undefined
      };

      const response = await apiClient.createUser(userData, adminToken);

      expect(response.status).toBe(400);
      expect(response.body.error).toBeDefined();
    });

    it('should handle whitespace-only strings', async () => {
      const userData = {
        email: '   ',
        username: '\t\t',
        firstName: '\n\n',
        lastName: '   \t\n   '
      };

      const response = await apiClient.createUser(userData, adminToken);

      expect(response.status).toBe(400);
      expect(response.body.error).toBeDefined();
    });
  });

  describe('Special Characters', () => {
    it('should handle special characters in names', async () => {
      const userData = {
        email: 'special@example.com',
        username: 'user_123',
        firstName: 'José-María',
        lastName: "O'Connor-Smith"
      };

      const response = await apiClient.createUser(userData, adminToken);

      expect(response.status).toBe(201);
      expect(response.body.firstName).toBe("José-María");
      expect(response.body.lastName).toBe("O'Connor-Smith");
      createdUserIds.push(response.body.id);
    });

    it('should handle unicode characters', async () => {
      const userData = {
        email: 'unicode@example.com',
        username: 'unicode_user',
        firstName: '测试',
        lastName: 'テスト'
      };

      const response = await apiClient.createUser(userData, adminToken);

      expect(response.status).toBe(201);
      expect(response.body.firstName).toBe('测试');
      expect(response.body.lastName).toBe('テスト');
      createdUserIds.push(response.body.id);
    });

    it('should handle emojis in names', async () => {
      const userData = {
        email: 'emoji@example.com',
        username: 'emoji_user',
        firstName: '🎯',
        lastName: '🚀'
      };

      const response = await apiClient.createUser(userData, adminToken);

      expect([201, 400]).toContain(response.status);
      if (response.status === 201) {
        createdUserIds.push(response.body.id);
      }
    });

    it('should reject script injection attempts', async () => {
      const userData = {
        email: 'script@example.com',
        username: 'scriptuser',
        firstName: '<script>alert("xss")</script>',
        lastName: '${rm -rf /}'
      };

      const response = await apiClient.createUser(userData, adminToken);

      expect([400, 201]).toContain(response.status);
      if (response.status === 201) {
        // If accepted, ensure it's properly sanitized
        expect(response.body.firstName).not.toContain('<script>');
        createdUserIds.push(response.body.id);
      }
    });
  });

  describe('Boundary Values', () => {
    it('should handle maximum length strings', async () => {
      const longString = 'a'.repeat(255); // Assuming 255 is max length
      const userData = {
        email: 'long@example.com',
        username: 'longuser',
        firstName: longString,
        lastName: longString
      };

      const response = await apiClient.createUser(userData, adminToken);

      expect([201, 400]).toContain(response.status);
      if (response.status === 201) {
        createdUserIds.push(response.body.id);
      } else {
        expect(response.body.message).toMatch(/length|long|maximum/i);
      }
    });

    it('should reject overly long strings', async () => {
      const tooLongString = 'a'.repeat(1000);
      const userData = {
        email: 'toolong@example.com',
        username: 'toolonguser',
        firstName: tooLongString,
        lastName: tooLongString
      };

      const response = await apiClient.createUser(userData, adminToken);

      expect(response.status).toBe(400);
      expect(response.body.error).toBeDefined();
      expect(response.body.message).toMatch(/length|long|maximum/i);
    });

    it('should handle minimum length usernames', async () => {
      const userData = {
        email: 'min@example.com',
        username: 'abc', // Minimum length (3 chars)
        firstName: 'Min',
        lastName: 'User'
      };

      const response = await apiClient.createUser(userData, adminToken);

      expect([201, 400]).toContain(response.status);
      if (response.status === 201) {
        createdUserIds.push(response.body.id);
      }
    });
  });

  describe('Email Edge Cases', () => {
    it('should handle email with plus sign', async () => {
      const userData = {
        email: 'user+test@example.com',
        username: 'plususer',
        firstName: 'Plus',
        lastName: 'User'
      };

      const response = await apiClient.createUser(userData, adminToken);

      expect(response.status).toBe(201);
      expect(response.body.email).toBe('user+test@example.com');
      createdUserIds.push(response.body.id);
    });

    it('should handle email with dots', async () => {
      const userData = {
        email: 'user.name@example.com',
        username: 'dotuser',
        firstName: 'Dot',
        lastName: 'User'
      };

      const response = await apiClient.createUser(userData, adminToken);

      expect(response.status).toBe(201);
      expect(response.body.email).toBe('user.name@example.com');
      createdUserIds.push(response.body.id);
    });

    it('should handle international domain names', async () => {
      const userData = {
        email: 'user@münchen.de',
        username: 'intluser',
        firstName: 'International',
        lastName: 'User'
      };

      const response = await apiClient.createUser(userData, adminToken);

      expect([201, 400]).toContain(response.status);
      if (response.status === 201) {
        createdUserIds.push(response.body.id);
      }
    });

    it('should reject emails without @ symbol', async () => {
      const userData = {
        email: 'invalid-email.com',
        username: 'invaliduser',
        firstName: 'Invalid',
        lastName: 'User'
      };

      const response = await apiClient.createUser(userData, adminToken);

      expect(response.status).toBe(400);
      expect(response.body.message).toMatch(/email|format|invalid/i);
    });

    it('should reject emails with multiple @ symbols', async () => {
      const userData = {
        email: 'user@@example.com',
        username: 'multiuser',
        firstName: 'Multi',
        lastName: 'User'
      };

      const response = await apiClient.createUser(userData, adminToken);

      expect(response.status).toBe(400);
      expect(response.body.message).toMatch(/email|format|invalid/i);
    });
  });

  describe('Case Sensitivity', () => {
    it('should handle case-insensitive email duplicates', async () => {
      const userData1 = {
        email: 'CASE@EXAMPLE.COM',
        username: 'caseuser1',
        firstName: 'Case',
        lastName: 'User1'
      };

      const userData2 = {
        email: 'case@example.com',
        username: 'caseuser2',
        firstName: 'Case',
        lastName: 'User2'
      };

      const response1 = await apiClient.createUser(userData1, adminToken);
      expect(response1.status).toBe(201);
      createdUserIds.push(response1.body.id);

      const response2 = await apiClient.createUser(userData2, adminToken);
      expect(response2.status).toBe(409); // Should detect duplicate
      expect(response2.body.message).toMatch(/email|duplicate|exists/i);
    });

    it('should handle case-insensitive username duplicates', async () => {
      const userData1 = {
        email: 'user1@example.com',
        username: 'USERNAME',
        firstName: 'User',
        lastName: 'One'
      };

      const userData2 = {
        email: 'user2@example.com',
        username: 'username',
        firstName: 'User',
        lastName: 'Two'
      };

      const response1 = await apiClient.createUser(userData1, adminToken);
      expect(response1.status).toBe(201);
      createdUserIds.push(response1.body.id);

      const response2 = await apiClient.createUser(userData2, adminToken);
      expect([409, 201]).toContain(response2.status);
      if (response2.status === 201) {
        createdUserIds.push(response2.body.id);
      }
    });
  });

  describe('Concurrent Operations', () => {
    it('should handle concurrent user creation with same email', async () => {
      const userData = {
        email: 'concurrent@example.com',
        username: 'concurrent1',
        firstName: 'Concurrent',
        lastName: 'User'
      };

      const userData2 = {
        email: 'concurrent@example.com',
        username: 'concurrent2',
        firstName: 'Concurrent',
        lastName: 'User2'
      };

      // Create both users simultaneously
      const [response1, response2] = await Promise.all([
        apiClient.createUser(userData, adminToken),
        apiClient.createUser(userData2, adminToken)
      ]);

      // One should succeed, one should fail with conflict
      const statuses = [response1.status, response2.status].sort();
      expect(statuses).toEqual([201, 409]);

      // Add successful user ID for cleanup
      if (response1.status === 201) createdUserIds.push(response1.body.id);
      if (response2.status === 201) createdUserIds.push(response2.body.id);
    });
  });
});