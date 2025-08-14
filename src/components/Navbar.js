import React from 'react';

const Navbar = ({ currentPage, setCurrentPage }) => {
  const navItems = [
    { id: 'home', label: 'Home' },
    { id: 'about', label: 'About' },
    { id: 'settings', label: 'Settings' }
  ];

  return (
    <nav className="navbar">
      <h1>Didactic Barnacle</h1>
      <ul className="nav-links">
        {navItems.map(item => (
          <li key={item.id}>
            <a
              href="#"
              className={currentPage === item.id ? 'active' : ''}
              onClick={(e) => {
                e.preventDefault();
                setCurrentPage(item.id);
              }}
            >
              {item.label}
            </a>
          </li>
        ))}
      </ul>
    </nav>
  );
};

export default Navbar;