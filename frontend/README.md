# User Management UI

A React-based frontend for managing users in the system. Built with TypeScript, Vite, and modern React practices.

## Features

- **User List View**: Display all users with filtering and pagination
- **User Detail View**: View detailed information about a specific user
- **Create/Edit User Form**: Add new users or modify existing ones
- **Delete Confirmation**: Safe user deletion with confirmation dialog
- **Responsive Design**: Works on desktop, tablet, and mobile devices
- **TypeScript Support**: Full type safety and autocompletion

## Components

### UserList
- Displays paginated list of users
- Filtering by name, role, and status
- Search functionality
- Actions: View, Edit, Delete

### UserDetail
- Modal display of user information
- Shows all user fields in a clean layout
- Quick access to edit and delete actions

### UserForm
- Handles both user creation and editing
- Form validation
- Role and status management
- Password requirements for new users

### DeleteConfirmation
- Safety confirmation for user deletion
- Requires typing "DELETE" to confirm
- Shows user details before deletion

## API Integration

The frontend integrates with a REST API at `/api/v1/users` with the following endpoints:

- `GET /api/v1/users` - List users with filtering
- `GET /api/v1/users/:id` - Get user by ID
- `POST /api/v1/users` - Create new user
- `PUT /api/v1/users/:id` - Update user
- `DELETE /api/v1/users/:id` - Delete user

## User Data Structure

```typescript
interface User {
  id: string;
  name: string;
  email: string;
  role: 'admin' | 'user' | 'moderator';
  status: 'active' | 'inactive' | 'suspended';
  createdAt: string;
  updatedAt: string;
}
```

## Getting Started

1. Install dependencies:
   ```bash
   npm install
   ```

2. Start development server:
   ```bash
   npm run dev
   ```

3. Build for production:
   ```bash
   npm run build
   ```

4. Preview production build:
   ```bash
   npm run preview
   ```

## Development

- **TypeScript**: Full type safety throughout the application
- **Vite**: Fast development server and build tool
- **ESLint**: Code linting and formatting
- **CSS**: Custom CSS with responsive design principles

## Configuration

The app is configured to proxy API requests to `http://localhost:8080` in development. Modify `vite.config.ts` to change the backend URL.

## Browser Support

- Chrome (latest)
- Firefox (latest)
- Safari (latest)
- Edge (latest)

## Folder Structure

```
src/
├── components/
│   └── users/
│       ├── UserList.tsx
│       ├── UserDetail.tsx
│       ├── UserForm.tsx
│       └── DeleteConfirmation.tsx
├── types/
│   └── user.ts
├── utils/
│   └── api.ts
├── App.tsx
├── App.css
└── main.tsx
```