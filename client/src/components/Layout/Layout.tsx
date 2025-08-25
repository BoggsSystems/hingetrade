import React from 'react';
import { Outlet } from 'react-router-dom';
import Navigation from './Navigation';
import styles from './Layout.module.css';

const Layout: React.FC = () => {
  return (
    <div className={styles.layout}>
      <Navigation />
      <main className={styles.main}>
        <Outlet />
      </main>
    </div>
  );
};

export default Layout;