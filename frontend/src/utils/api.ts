import { User, CreateUserRequest, UpdateUserRequest, UserListResponse, UserFilters } from '../types/user';

const API_BASE_URL = '/api/v1';

class ApiError extends Error {
  constructor(public status: number, message: string) {
    super(message);
    this.name = 'ApiError';
  }
}

async function apiRequest<T>(url: string, options: RequestInit = {}): Promise<T> {
  const response = await fetch(`${API_BASE_URL}${url}`, {
    headers: {
      'Content-Type': 'application/json',
      ...options.headers,
    },
    ...options,
  });

  if (!response.ok) {
    throw new ApiError(response.status, `API request failed: ${response.statusText}`);
  }

  return response.json();
}

export const userApi = {
  async getUsers(filters: UserFilters = {}): Promise<UserListResponse> {
    const params = new URLSearchParams();
    Object.entries(filters).forEach(([key, value]) => {
      if (value !== undefined) {
        params.append(key, value.toString());
      }
    });
    
    const queryString = params.toString();
    return apiRequest<UserListResponse>(`/users${queryString ? `?${queryString}` : ''}`);
  },

  async getUserById(id: string): Promise<User> {
    return apiRequest<User>(`/users/${id}`);
  },

  async createUser(userData: CreateUserRequest): Promise<User> {
    return apiRequest<User>('/users', {
      method: 'POST',
      body: JSON.stringify(userData),
    });
  },

  async updateUser(id: string, userData: UpdateUserRequest): Promise<User> {
    return apiRequest<User>(`/users/${id}`, {
      method: 'PUT',
      body: JSON.stringify(userData),
    });
  },

  async deleteUser(id: string): Promise<void> {
    await apiRequest<void>(`/users/${id}`, {
      method: 'DELETE',
    });
  },
};