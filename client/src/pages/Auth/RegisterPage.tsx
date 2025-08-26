import React, { useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { debugLogger } from '../../utils/debugLogger';
import DebugPanel from '../../components/Debug/DebugPanel';
import styles from './AuthPages.module.css';

const RegisterPage: React.FC = () => {
  const navigate = useNavigate();
  
  useEffect(() => {
    debugLogger.info('RegisterPage loaded - redirecting to onboarding');
    // Immediately redirect to the onboarding page
    navigate('/onboarding');
  }, [navigate]);
  
  // This will only show briefly before redirect
  return (
    <div className={styles.authContainer}>
      <div style={{ 
        textAlign: 'center', 
        marginTop: '100px',
        color: '#999'
      }}>
        <p>Redirecting to onboarding...</p>
      </div>
      
      <DebugPanel />
    </div>
  );
};

export default RegisterPage;