import React, { useState } from 'react';
import { NavLink } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import styles from './Navigation.module.css';

const Navigation: React.FC = () => {
  const { user, logout } = useAuth();
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);

  const navItems = [
    { path: '/dashboard', label: 'Dashboard', icon: '📊' },
    { path: '/markets', label: 'Markets', icon: '📈' },
    { path: '/portfolio', label: 'Portfolio', icon: '💼' },
    { path: '/trading', label: 'Trade', icon: '💱' },
    { path: '/alerts', label: 'Alerts', icon: '🔔' },
  ];

  return (
    <>
      <nav className={styles.navigation}>
        <div className={styles.logo}>
          <h2>HingeTrade</h2>
        </div>

        <div className={styles.navItems}>
          {navItems.map((item) => (
            <NavLink
              key={item.path}
              to={item.path}
              className={({ isActive }) =>
                `${styles.navItem} ${isActive ? styles.active : ''}`
              }
            >
              <span className={styles.icon}>{item.icon}</span>
              <span className={styles.label}>{item.label}</span>
            </NavLink>
          ))}
        </div>

        <div className={styles.userSection}>
          {user && (
            <div className={styles.userInfo}>
              <img
                src={`https://ui-avatars.com/api/?name=${user.username}`}
                alt={user.username}
                className={styles.avatar}
              />
              <span className={styles.userName}>{user.username}</span>
            </div>
          )}
          <button onClick={logout} className={styles.logoutButton}>
            Logout
          </button>
        </div>

        <button
          className={styles.mobileMenuToggle}
          onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
        >
          <span></span>
          <span></span>
          <span></span>
        </button>
      </nav>

      {/* Mobile Navigation */}
      <div className={`${styles.mobileNav} ${isMobileMenuOpen ? styles.open : ''}`}>
        <div className={styles.mobileNavItems}>
          {navItems.map((item) => (
            <NavLink
              key={item.path}
              to={item.path}
              className={({ isActive }) =>
                `${styles.mobileNavItem} ${isActive ? styles.active : ''}`
              }
              onClick={() => setIsMobileMenuOpen(false)}
            >
              <span className={styles.icon}>{item.icon}</span>
              <span className={styles.label}>{item.label}</span>
            </NavLink>
          ))}
        </div>
        <div className={styles.mobileUserSection}>
          {user && (
            <div className={styles.userInfo}>
              <img
                src={`https://ui-avatars.com/api/?name=${user.username}`}
                alt={user.username}
                className={styles.avatar}
              />
              <span className={styles.userName}>{user.username}</span>
            </div>
          )}
          <button onClick={logout} className={styles.logoutButton}>
            Logout
          </button>
        </div>
      </div>
    </>
  );
};

export default Navigation;