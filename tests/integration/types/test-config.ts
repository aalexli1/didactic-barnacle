export interface TestConfig {
  baseUrl: string;
  timeout: number;
  retries: number;
  auth: {
    adminToken: string;
    userToken: string;
  };
}

export interface User {
  id?: string;
  email: string;
  username: string;
  firstName: string;
  lastName: string;
  role?: 'admin' | 'user';
  createdAt?: string;
  updatedAt?: string;
}

export interface ApiError {
  error: string;
  message: string;
  statusCode: number;
  timestamp: string;
}

export interface PaginatedResponse<T> {
  data: T[];
  pagination: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
  };
}