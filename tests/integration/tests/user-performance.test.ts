import { ApiClient } from '../utils/api-client';
import { User } from '../types/test-config';

describe('User API Performance Tests', () => {
  let apiClient: ApiClient;
  let adminToken: string;
  let createdUserIds: string[] = [];

  beforeAll(async () => {
    apiClient = new ApiClient();
    adminToken = await apiClient.authenticateAsAdmin();
  });

  afterAll(async () => {
    // Clean up all created users
    const cleanupPromises = createdUserIds.map(id => 
      apiClient.deleteUser(id, adminToken).catch(() => {})
    );
    await Promise.all(cleanupPromises);
  });

  describe('Response Time Tests', () => {
    it('should respond to GET /api/users within acceptable time', async () => {
      const startTime = Date.now();
      const response = await apiClient.getUsers(adminToken);
      const responseTime = Date.now() - startTime;

      expect(response.status).toBe(200);
      expect(responseTime).toBeLessThan(2000); // Should respond within 2 seconds
    });

    it('should respond to POST /api/users within acceptable time', async () => {
      const userData: Partial<User> = {
        email: `perf-test-${Date.now()}@example.com`,
        username: `perfuser${Date.now()}`,
        firstName: 'Performance',
        lastName: 'Test'
      };

      const startTime = Date.now();
      const response = await apiClient.createUser(userData, adminToken);
      const responseTime = Date.now() - startTime;

      expect(response.status).toBe(201);
      expect(responseTime).toBeLessThan(3000); // Should respond within 3 seconds
      createdUserIds.push(response.body.id);
    });

    it('should respond to GET /api/users/:id within acceptable time', async () => {
      // Create a user first
      const userData: Partial<User> = {
        email: `get-perf-test-${Date.now()}@example.com`,
        username: `getperfuser${Date.now()}`,
        firstName: 'GetPerf',
        lastName: 'Test'
      };

      const createResponse = await apiClient.createUser(userData, adminToken);
      const userId = createResponse.body.id;
      createdUserIds.push(userId);

      const startTime = Date.now();
      const response = await apiClient.getUserById(userId, adminToken);
      const responseTime = Date.now() - startTime;

      expect(response.status).toBe(200);
      expect(responseTime).toBeLessThan(1500); // Should respond within 1.5 seconds
    });
  });

  describe('Concurrent Request Tests', () => {
    it('should handle multiple concurrent GET requests', async () => {
      const concurrentRequests = 10;
      const promises = Array(concurrentRequests).fill(null).map(() => 
        apiClient.getUsers(adminToken)
      );

      const startTime = Date.now();
      const responses = await Promise.all(promises);
      const totalTime = Date.now() - startTime;

      // All requests should succeed
      responses.forEach(response => {
        expect(response.status).toBe(200);
      });

      // Total time should be reasonable (not much more than a single request)
      expect(totalTime).toBeLessThan(5000);
    });

    it('should handle concurrent user creation', async () => {
      const concurrentUsers = 5;
      const userPromises = Array(concurrentUsers).fill(null).map((_, index) => {
        const userData: Partial<User> = {
          email: `concurrent-${Date.now()}-${index}@example.com`,
          username: `concurrent${Date.now()}${index}`,
          firstName: `Concurrent${index}`,
          lastName: 'Test'
        };
        return apiClient.createUser(userData, adminToken);
      });

      const startTime = Date.now();
      const responses = await Promise.all(userPromises);
      const totalTime = Date.now() - startTime;

      // All requests should succeed
      responses.forEach((response: any) => {
        expect(response.status).toBe(201);
        createdUserIds.push(response.body.id);
      });

      // Should complete within reasonable time
      expect(totalTime).toBeLessThan(10000);
    });
  });

  describe('Pagination Performance', () => {
    beforeAll(async () => {
      // Create multiple users for pagination testing
      const userPromises = Array(20).fill(null).map((_, index) => {
        const userData: Partial<User> = {
          email: `pagination-${Date.now()}-${index}@example.com`,
          username: `paginationuser${Date.now()}${index}`,
          firstName: `Pagination${index}`,
          lastName: 'Test'
        };
        return apiClient.createUser(userData, adminToken);
      });

      const responses = await Promise.all(userPromises);
      responses.forEach((response: any) => {
        if (response.status === 201) {
          createdUserIds.push(response.body.id);
        }
      });
    });

    it('should handle large page sizes efficiently', async () => {
      const startTime = Date.now();
      const response = await apiClient.getUsers(adminToken, { 
        page: 1, 
        limit: 50 
      });
      const responseTime = Date.now() - startTime;

      expect(response.status).toBe(200);
      expect(responseTime).toBeLessThan(3000);
      expect(response.body.pagination).toBeDefined();
    });

    it('should handle multiple page requests efficiently', async () => {
      const pagePromises = [1, 2, 3, 4, 5].map(page =>
        apiClient.getUsers(adminToken, { page, limit: 5 })
      );

      const startTime = Date.now();
      const responses = await Promise.all(pagePromises);
      const totalTime = Date.now() - startTime;

      responses.forEach(response => {
        expect(response.status).toBe(200);
        expect(response.body.pagination.page).toBeDefined();
      });

      expect(totalTime).toBeLessThan(8000);
    });
  });

  describe('Memory and Resource Tests', () => {
    it('should handle bulk user creation without memory issues', async () => {
      const bulkSize = 50;
      const userPromises = Array(bulkSize).fill(null).map((_, index) => {
        const userData: Partial<User> = {
          email: `bulk-${Date.now()}-${index}@example.com`,
          username: `bulkuser${Date.now()}${index}`,
          firstName: `Bulk${index}`,
          lastName: 'Test'
        };
        return apiClient.createUser(userData, adminToken);
      });

      const startTime = Date.now();
      
      // Process in batches to avoid overwhelming the server
      const batchSize = 10;
      const batches = [];
      for (let i = 0; i < userPromises.length; i += batchSize) {
        batches.push(userPromises.slice(i, i + batchSize));
      }

      for (const batch of batches) {
        const responses = await Promise.all(batch);
        responses.forEach((response: any) => {
          if (response.status === 201) {
            createdUserIds.push(response.body.id);
          }
        });
        
        // Small delay between batches
        await new Promise(resolve => setTimeout(resolve, 100));
      }

      const totalTime = Date.now() - startTime;
      
      // Should complete within reasonable time
      expect(totalTime).toBeLessThan(30000); // 30 seconds for 50 users
    });

    it('should maintain consistent performance with growing dataset', async () => {
      // Test performance with current dataset size
      const startTime1 = Date.now();
      const response1 = await apiClient.getUsers(adminToken, { limit: 20 });
      const time1 = Date.now() - startTime1;

      // Add more users
      const additionalUsers = Array(30).fill(null).map((_, index) => {
        const userData: Partial<User> = {
          email: `dataset-${Date.now()}-${index}@example.com`,
          username: `datasetuser${Date.now()}${index}`,
          firstName: `Dataset${index}`,
          lastName: 'Test'
        };
        return apiClient.createUser(userData, adminToken);
      });

      const createResponses = await Promise.all(additionalUsers);
      createResponses.forEach((response: any) => {
        if (response.status === 201) {
          createdUserIds.push(response.body.id);
        }
      });

      // Test performance with larger dataset
      const startTime2 = Date.now();
      const response2 = await apiClient.getUsers(adminToken, { limit: 20 });
      const time2 = Date.now() - startTime2;

      expect(response1.status).toBe(200);
      expect(response2.status).toBe(200);
      
      // Performance should not degrade significantly
      expect(time2).toBeLessThan(time1 * 2); // At most 2x slower
    });
  });
});