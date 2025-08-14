import React from 'react';
import { useTheme } from '../contexts/ThemeContext';

const Settings = () => {
  const { isDarkMode, toggleTheme } = useTheme();

  return (
    <div className="page">
      <h2>Settings</h2>
      
      <div className="settings-section">
        <h3>Appearance</h3>
        <div className="toggle-container">
          <div>
            <strong>Dark Mode</strong>
            <p style={{ fontSize: '0.875rem', opacity: 0.8, margin: '0.25rem 0' }}>
              Switch between light and dark themes
            </p>
          </div>
          <div style={{ display: 'flex', alignItems: 'center' }}>
            <label className="toggle-switch">
              <input
                type="checkbox"
                checked={isDarkMode}
                onChange={toggleTheme}
              />
              <span className="toggle-slider"></span>
            </label>
            <span className="keyboard-shortcut">
              ⌘⇧D
            </span>
          </div>
        </div>
      </div>

      <div className="settings-section">
        <h3>Theme Information</h3>
        <p>
          <strong>Current Theme:</strong> {isDarkMode ? 'Dark' : 'Light'}
        </p>
        <p style={{ fontSize: '0.875rem', opacity: 0.8, marginTop: '0.5rem' }}>
          Your theme preference is automatically saved and will be restored when you visit the site again.
          The application also respects your system's theme preference if you haven't manually selected one.
        </p>
      </div>

      <div className="settings-section">
        <h3>Keyboard Shortcuts</h3>
        <div style={{ fontSize: '0.875rem' }}>
          <p><strong>⌘⇧D</strong> (Mac) or <strong>Ctrl+Shift+D</strong> (Windows/Linux): Toggle dark mode</p>
        </div>
      </div>
    </div>
  );
};

export default Settings;