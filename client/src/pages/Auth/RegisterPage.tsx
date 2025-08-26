import React, { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import { KYCOnboardingModal } from '../../components/Onboarding';
import type { KYCData } from '../../components/Onboarding';
import styles from './AuthPages.module.css';

const RegisterPage: React.FC = () => {
  const navigate = useNavigate();
  const { register } = useAuth();
  const [showKYCModal, setShowKYCModal] = useState(true);
  const [registrationError, setRegistrationError] = useState<string>('');
  
  // Open modal immediately when page loads
  useEffect(() => {
    setShowKYCModal(true);
  }, []);
  
  const handleRegister = async (email: string, password: string, username: string) => {
    try {
      setRegistrationError('');
      const user = await register(email, password, username);
      return user;
    } catch (err: any) {
      // Extract error message
      let errorMessage = 'Registration failed. Please try again.';
      
      if (err.response?.data?.errors) {
        // Handle validation errors from the server
        const serverErrors = err.response.data.errors;
        const errorMessages = [];
        
        for (const [field, messages] of Object.entries(serverErrors)) {
          const message = Array.isArray(messages) ? messages[0] : messages;
          errorMessages.push(`${field}: ${message}`);
        }
        
        errorMessage = errorMessages.join(', ');
      } else if (err.response?.data?.message) {
        errorMessage = err.response.data.message;
      }
      
      setRegistrationError(errorMessage);
      throw new Error(errorMessage);
    }
  };
  
  const handleKYCComplete = async (kycData: KYCData) => {
    try {
      // TODO: Submit remaining KYC data to backend
      console.log('Complete KYC Data:', kycData);
      
      // Navigate to dashboard after completion
      navigate('/dashboard');
    } catch (err) {
      console.error('KYC submission failed:', err);
      // Handle error
    }
  };
  
  const handleKYCClose = () => {
    setShowKYCModal(false);
    // Navigate back to landing or login
    navigate('/');
  };
  
  // Simple page that just shows a backdrop with the modal
  return (
    <div className={styles.authContainer}>
      <div style={{ 
        textAlign: 'center', 
        marginTop: '100px',
        color: '#999'
      }}>
        <h2 style={{ marginBottom: '16px' }}>Create Your Trading Account</h2>
        <p>Complete our simple onboarding process to get started.</p>
        
        {!showKYCModal && (
          <button 
            onClick={() => setShowKYCModal(true)}
            className={styles.submitButton}
            style={{ marginTop: '32px' }}
          >
            Start Onboarding
          </button>
        )}
        
        <div className={styles.authFooter} style={{ marginTop: '48px' }}>
          <p>
            Already have an account?{' '}
            <Link to="/login">Sign in</Link>
          </p>
        </div>
      </div>
      
      <KYCOnboardingModal
        isOpen={showKYCModal}
        onClose={handleKYCClose}
        onComplete={handleKYCComplete}
        onRegister={handleRegister}
      />
      
      {registrationError && (
        <div style={{
          position: 'fixed',
          bottom: '20px',
          left: '50%',
          transform: 'translateX(-50%)',
          backgroundColor: '#f44336',
          color: 'white',
          padding: '12px 24px',
          borderRadius: '4px',
          boxShadow: '0 2px 8px rgba(0,0,0,0.2)',
          zIndex: 1001
        }}>
          {registrationError}
        </div>
      )}
    </div>
  );
};

export default RegisterPage;