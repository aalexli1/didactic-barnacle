import { User } from '../types/user';

export const mockUsers: User[] = [
  {
    id: '1',
    name: 'John Doe',
    email: 'john.doe@example.com',
    role: 'admin',
    status: 'active',
    createdAt: '2024-01-15T10:30:00Z',
    updatedAt: '2024-01-20T14:45:00Z',
  },
  {
    id: '2',
    name: 'Jane Smith',
    email: 'jane.smith@example.com',
    role: 'moderator',
    status: 'active',
    createdAt: '2024-01-16T09:15:00Z',
    updatedAt: '2024-01-18T11:20:00Z',
  },
  {
    id: '3',
    name: 'Bob Johnson',
    email: 'bob.johnson@example.com',
    role: 'user',
    status: 'inactive',
    createdAt: '2024-01-17T16:45:00Z',
    updatedAt: '2024-01-17T16:45:00Z',
  },
  {
    id: '4',
    name: 'Alice Brown',
    email: 'alice.brown@example.com',
    role: 'user',
    status: 'suspended',
    createdAt: '2024-01-18T08:30:00Z',
    updatedAt: '2024-01-22T13:15:00Z',
  },
  {
    id: '5',
    name: 'Charlie Wilson',
    email: 'charlie.wilson@example.com',
    role: 'moderator',
    status: 'active',
    createdAt: '2024-01-19T12:00:00Z',
    updatedAt: '2024-01-21T10:30:00Z',
  },
];