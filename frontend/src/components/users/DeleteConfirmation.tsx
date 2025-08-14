import React, { useState } from 'react';
import { User } from '../../types/user';
import { userApi } from '../../utils/api';

interface DeleteConfirmationProps {
  user: User | null;
  isOpen: boolean;
  onClose: () => void;
  onSuccess: () => void;
}

export const DeleteConfirmation: React.FC<DeleteConfirmationProps> = ({
  user,
  isOpen,
  onClose,
  onSuccess,
}) => {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [confirmText, setConfirmText] = useState('');

  const handleDelete = async () => {
    if (!user || confirmText !== 'DELETE') {
      return;
    }

    setLoading(true);
    setError(null);

    try {
      await userApi.deleteUser(user.id);
      onSuccess();
      onClose();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to delete user');
    } finally {
      setLoading(false);
    }
  };

  const handleClose = () => {
    setConfirmText('');
    setError(null);
    onClose();
  };

  if (!isOpen || !user) {
    return null;
  }

  const canDelete = confirmText === 'DELETE' && !loading;

  return (
    <div className="delete-confirmation-modal">
      <div className="modal-content">
        <div className="modal-header">
          <h3>Delete User</h3>
          <button onClick={handleClose} className="close-btn">&times;</button>
        </div>
        
        <div className="modal-body">
          <div className="warning-icon">⚠️</div>
          
          <div className="warning-message">
            <h4>Are you sure you want to delete this user?</h4>
            <p>
              This action will permanently remove <strong>{user.name}</strong> ({user.email}) 
              from the system. This action cannot be undone.
            </p>
          </div>
          
          <div className="user-details">
            <div className="detail-row">
              <span className="label">Name:</span>
              <span className="value">{user.name}</span>
            </div>
            <div className="detail-row">
              <span className="label">Email:</span>
              <span className="value">{user.email}</span>
            </div>
            <div className="detail-row">
              <span className="label">Role:</span>
              <span className="value">{user.role}</span>
            </div>
            <div className="detail-row">
              <span className="label">Status:</span>
              <span className="value">{user.status}</span>
            </div>
          </div>
          
          <div className="confirmation-input">
            <label htmlFor="confirm-delete">
              Type <strong>DELETE</strong> to confirm:
            </label>
            <input
              type="text"
              id="confirm-delete"
              value={confirmText}
              onChange={(e) => setConfirmText(e.target.value)}
              placeholder="Type DELETE here"
              className={confirmText === 'DELETE' ? 'valid' : ''}
              disabled={loading}
            />
          </div>
          
          {error && <div className="error">{error}</div>}
        </div>
        
        <div className="modal-actions">
          <button
            onClick={handleDelete}
            disabled={!canDelete}
            className="btn btn-danger"
          >
            {loading ? 'Deleting...' : 'Delete User'}
          </button>
          <button
            onClick={handleClose}
            disabled={loading}
            className="btn btn-secondary"
          >
            Cancel
          </button>
        </div>
      </div>
    </div>
  );
};