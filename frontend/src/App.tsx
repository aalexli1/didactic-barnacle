import { useState } from 'react';
import { User } from './types/user';
import { UserList } from './components/users/UserList';
import { UserDetail } from './components/users/UserDetail';
import { UserForm } from './components/users/UserForm';
import { DeleteConfirmation } from './components/users/DeleteConfirmation';
import './App.css';

function App() {
  const [selectedUserId, setSelectedUserId] = useState<string | null>(null);
  const [showUserForm, setShowUserForm] = useState(false);
  const [showDeleteConfirmation, setShowDeleteConfirmation] = useState(false);
  const [editingUser, setEditingUser] = useState<User | null>(null);
  const [deletingUser, setDeletingUser] = useState<User | null>(null);
  const [refreshKey, setRefreshKey] = useState(0);

  const handleSelectUser = (user: User) => {
    setSelectedUserId(user.id);
  };

  const handleCloseUserDetail = () => {
    setSelectedUserId(null);
  };

  const handleCreateUser = () => {
    setEditingUser(null);
    setShowUserForm(true);
  };

  const handleEditUser = (user: User) => {
    setEditingUser(user);
    setShowUserForm(true);
    setSelectedUserId(null);
  };

  const handleDeleteUser = (user: User) => {
    setDeletingUser(user);
    setShowDeleteConfirmation(true);
    setSelectedUserId(null);
  };

  const handleCloseUserForm = () => {
    setShowUserForm(false);
    setEditingUser(null);
  };

  const handleCloseDeleteConfirmation = () => {
    setShowDeleteConfirmation(false);
    setDeletingUser(null);
  };

  const handleUserSuccess = () => {
    setRefreshKey(prev => prev + 1);
  };

  return (
    <div className="app">
      <header className="app-header">
        <h1>User Management System</h1>
        <p>Manage users, roles, and permissions</p>
      </header>

      <main className="app-main">
        <UserList
          key={refreshKey}
          onSelectUser={handleSelectUser}
          onCreateUser={handleCreateUser}
          onEditUser={handleEditUser}
          onDeleteUser={handleDeleteUser}
        />
      </main>

      <UserDetail
        userId={selectedUserId}
        onClose={handleCloseUserDetail}
        onEdit={handleEditUser}
        onDelete={handleDeleteUser}
      />

      <UserForm
        user={editingUser}
        isOpen={showUserForm}
        onClose={handleCloseUserForm}
        onSuccess={handleUserSuccess}
      />

      <DeleteConfirmation
        user={deletingUser}
        isOpen={showDeleteConfirmation}
        onClose={handleCloseDeleteConfirmation}
        onSuccess={handleUserSuccess}
      />
    </div>
  );
}

export default App;