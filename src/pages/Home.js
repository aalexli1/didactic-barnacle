import React from 'react';

const Home = () => {
  return (
    <div className="page">
      <h2>Welcome to Didactic Barnacle</h2>
      <div className="card">
        <p>
          This is a sample web application that demonstrates dark mode functionality.
          The theme can be toggled in the Settings page and will persist across sessions.
        </p>
      </div>
      <div className="card">
        <h3>Features</h3>
        <ul>
          <li>Dark/Light mode toggle</li>
          <li>System preference detection</li>
          <li>Smooth transitions</li>
          <li>Keyboard shortcut (Cmd+Shift+D)</li>
          <li>LocalStorage persistence</li>
        </ul>
      </div>
    </div>
  );
};

export default Home;