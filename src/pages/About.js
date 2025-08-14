import React from 'react';

const About = () => {
  return (
    <div className="page">
      <h2>About</h2>
      <div className="card">
        <p>
          Didactic Barnacle is a demonstration project showcasing modern web development
          practices including theme management and user experience design.
        </p>
        <p>
          The application supports both light and dark themes, automatically detects
          system preferences, and provides users with manual control over their
          preferred theme.
        </p>
      </div>
      <div className="card">
        <h3>Technical Details</h3>
        <p>Built with:</p>
        <ul>
          <li>React 18</li>
          <li>CSS Custom Properties (Variables)</li>
          <li>Context API for state management</li>
          <li>LocalStorage for persistence</li>
          <li>Media queries for system preference detection</li>
        </ul>
      </div>
    </div>
  );
};

export default About;