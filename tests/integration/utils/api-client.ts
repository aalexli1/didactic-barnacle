import request from 'supertest';
import { testConfig } from '../setup/test-setup';
import { User, ApiError } from '../types/test-config';

export class ApiClient {
  private baseUrl: string;

  constructor(baseUrl: string = testConfig.baseUrl) {
    this.baseUrl = baseUrl;
  }

  // Helper method to make authenticated requests
  private makeRequest(method: 'get' | 'post' | 'put' | 'delete', endpoint: string, token?: string) {
    const req = request(this.baseUrl)[method](endpoint);
    
    if (token) {
      req.set('Authorization', `Bearer ${token}`);
    }
    
    return req;
  }

  // User API methods
  async getUsers(token?: string, query?: Record<string, any>) {
    const req = this.makeRequest('get', '/api/users', token);
    if (query) {
      req.query(query);
    }
    return req;
  }

  async getUserById(id: string, token?: string) {
    return this.makeRequest('get', `/api/users/${id}`, token);
  }

  async createUser(userData: Partial<User>, token?: string) {
    return this.makeRequest('post', '/api/users', token).send(userData);
  }

  async updateUser(id: string, userData: Partial<User>, token?: string) {
    return this.makeRequest('put', `/api/users/${id}`, token).send(userData);
  }

  async deleteUser(id: string, token?: string) {
    return this.makeRequest('delete', `/api/users/${id}`, token);
  }

  // Auth helper methods
  async authenticateAsAdmin() {
    return testConfig.auth.adminToken;
  }

  async authenticateAsUser() {
    return testConfig.auth.userToken;
  }
}