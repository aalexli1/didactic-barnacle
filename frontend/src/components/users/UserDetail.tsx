import React, { useState, useEffect } from 'react';
import { User } from '../../types/user';
import { userApi } from '../../utils/api';

interface UserDetailProps {
  userId: string | null;
  onClose: () => void;
  onEdit: (user: User) => void;
  onDelete: (user: User) => void;
}

export const UserDetail: React.FC<UserDetailProps> = ({
  userId,
  onClose,
  onEdit,
  onDelete,
}) => {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (userId) {
      loadUser(userId);
    }
  }, [userId]);

  const loadUser = async (id: string) => {
    setLoading(true);
    setError(null);
    try {
      const userData = await userApi.getUserById(id);
      setUser(userData);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load user');
    } finally {
      setLoading(false);
    }
  };

  if (!userId) {
    return null;
  }

  if (loading) {
    return (
      <div className="user-detail-modal">
        <div className="modal-content">
          <div className="loading">Loading user details...</div>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="user-detail-modal">
        <div className="modal-content">
          <div className="modal-header">
            <h3>Error</h3>
            <button onClick={onClose} className="close-btn">&times;</button>
          </div>
          <div className="error">{error}</div>
        </div>
      </div>
    );
  }

  if (!user) {
    return null;
  }

  const getRoleColor = (role: string) => {
    switch (role) {
      case 'admin': return 'red';
      case 'moderator': return 'orange';
      default: return 'blue';
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'active': return 'green';
      case 'suspended': return 'red';
      default: return 'gray';
    }
  };

  return (
    <div className="user-detail-modal">
      <div className="modal-content">
        <div className="modal-header">
          <h3>User Details</h3>
          <button onClick={onClose} className="close-btn">&times;</button>
        </div>
        
        <div className="user-detail-content">
          <div className="user-avatar">
            <div className="avatar-placeholder">
              {user.name.charAt(0).toUpperCase()}
            </div>
          </div>
          
          <div className="user-info">
            <div className="field-group">
              <label>Name</label>
              <div className="field-value">{user.name}</div>
            </div>
            
            <div className="field-group">
              <label>Email</label>
              <div className="field-value">{user.email}</div>
            </div>
            
            <div className="field-group">
              <label>Role</label>
              <div className="field-value">
                <span className={`role-badge role-${getRoleColor(user.role)}`}>
                  {user.role}
                </span>
              </div>
            </div>
            
            <div className="field-group">
              <label>Status</label>
              <div className="field-value">
                <span className={`status-badge status-${getStatusColor(user.status)}`}>
                  {user.status}
                </span>
              </div>
            </div>
            
            <div className="field-group">
              <label>Created</label>
              <div className="field-value">
                {new Date(user.createdAt).toLocaleDateString()} at{' '}
                {new Date(user.createdAt).toLocaleTimeString()}
              </div>
            </div>
            
            <div className="field-group">
              <label>Last Updated</label>
              <div className="field-value">
                {new Date(user.updatedAt).toLocaleDateString()} at{' '}
                {new Date(user.updatedAt).toLocaleTimeString()}
              </div>
            </div>
          </div>
        </div>
        
        <div className="modal-actions">
          <button
            onClick={() => onEdit(user)}
            className="btn btn-primary"
          >
            Edit User
          </button>
          <button
            onClick={() => onDelete(user)}
            className="btn btn-danger"
          >
            Delete User
          </button>
          <button
            onClick={onClose}
            className="btn btn-secondary"
          >
            Close
          </button>
        </div>
      </div>
    </div>
  );
};