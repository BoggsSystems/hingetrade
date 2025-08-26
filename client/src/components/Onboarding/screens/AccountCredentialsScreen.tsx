import React, { useState } from 'react';
import LegalDocumentModal from '../../Legal/LegalDocumentModal';
import TermsOfServiceContent from '../../Legal/TermsOfServiceContent';
import PrivacyPolicyContent from '../../Legal/PrivacyPolicyContent';

interface AccountCredentialsScreenProps {
  onNext: (data: AccountCredentialsData) => void | Promise<void>;
  data?: AccountCredentialsData;
}

export interface AccountCredentialsData {
  email: string;
  username: string;
  password: string;
  confirmPassword: string;
}

const AccountCredentialsScreen: React.FC<AccountCredentialsScreenProps> = ({ onNext, data }) => {
  // Generate random test data for development
  const generateTestData = () => {
    const timestamp = Date.now();
    const randomNum = Math.floor(Math.random() * 1000);
    const testEmail = `testuser${timestamp}${randomNum}@example.com`;
    const testUsername = `testuser${timestamp}${randomNum}`;
    const testPassword = 'TestPassword123@';
    
    return {
      email: testEmail,
      username: testUsername,
      password: testPassword,
      confirmPassword: testPassword
    };
  };

  const [formData, setFormData] = useState<AccountCredentialsData>(
    data || generateTestData()
  );
  
  const [errors, setErrors] = useState<Partial<AccountCredentialsData>>({});
  const [showPassword, setShowPassword] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [serverError, setServerError] = useState('');
  const [showTermsModal, setShowTermsModal] = useState(false);
  const [showPrivacyModal, setShowPrivacyModal] = useState(false);
  
  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
    
    // Clear error when user starts typing
    if (errors[name as keyof AccountCredentialsData]) {
      setErrors(prev => ({ ...prev, [name]: '' }));
    }
  };
  
  const validateForm = () => {
    const newErrors: Partial<AccountCredentialsData> = {};
    
    // Email validation
    if (!formData.email.trim()) {
      newErrors.email = 'Email is required';
    } else if (!/\S+@\S+\.\S+/.test(formData.email)) {
      newErrors.email = 'Invalid email address';
    }
    
    // Username validation
    if (!formData.username.trim()) {
      newErrors.username = 'Username is required';
    } else if (formData.username.length < 3) {
      newErrors.username = 'Username must be at least 3 characters';
    } else if (!/^[a-zA-Z0-9._-]+$/.test(formData.username)) {
      newErrors.username = 'Username can only contain letters, numbers, dots, underscores, and hyphens';
    }
    
    // Password validation
    if (!formData.password) {
      newErrors.password = 'Password is required';
    } else if (formData.password.length < 8) {
      newErrors.password = 'Password must be at least 8 characters';
    } else if (!/(?=.*[a-z])/.test(formData.password)) {
      newErrors.password = 'Password must contain at least one lowercase letter';
    } else if (!/(?=.*[A-Z])/.test(formData.password)) {
      newErrors.password = 'Password must contain at least one uppercase letter';
    } else if (!/(?=.*\d)/.test(formData.password)) {
      newErrors.password = 'Password must contain at least one number';
    } else if (!/(?=.*[@$!%*?&])/.test(formData.password)) {
      newErrors.password = 'Password must contain at least one special character';
    }
    
    // Confirm password validation
    if (!formData.confirmPassword) {
      newErrors.confirmPassword = 'Please confirm your password';
    } else if (formData.password !== formData.confirmPassword) {
      newErrors.confirmPassword = 'Passwords do not match';
    }
    
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };
  
  const handleSubmit = async () => {
    if (!validateForm()) {
      return;
    }
    
    setIsSubmitting(true);
    setServerError('');
    
    try {
      await onNext(formData);
    } catch (error: any) {
      console.error('Registration error:', error);
      setServerError(error.message || 'Registration failed. Please try again.');
    } finally {
      setIsSubmitting(false);
    }
  };
  
  return (
    <div className="screen-content">
      <h1>Create Your Account</h1>
      <p>Let's start with your account credentials.</p>
      
      <div className="form-group">
        <label htmlFor="email">Email Address</label>
        <input
          type="email"
          id="email"
          name="email"
          value={formData.email}
          onChange={handleChange}
          placeholder="john.doe@example.com"
          autoComplete="email"
          autoFocus
        />
        {errors.email && <div className="error-message">{errors.email}</div>}
      </div>
      
      <div className="form-group">
        <label htmlFor="username">Username</label>
        <input
          type="text"
          id="username"
          name="username"
          value={formData.username}
          onChange={handleChange}
          placeholder="johndoe"
          autoComplete="username"
        />
        {errors.username && <div className="error-message">{errors.username}</div>}
        <div className="help-text">This will be your unique identifier on the platform</div>
      </div>
      
      <div className="form-group">
        <label htmlFor="password">Password</label>
        <div style={{ position: 'relative' }}>
          <input
            type={showPassword ? "text" : "password"}
            id="password"
            name="password"
            value={formData.password}
            onChange={handleChange}
            placeholder="••••••••"
            autoComplete="new-password"
          />
          <button
            type="button"
            onClick={() => setShowPassword(!showPassword)}
            style={{
              position: 'absolute',
              right: '10px',
              top: '50%',
              transform: 'translateY(-50%)',
              background: 'none',
              border: 'none',
              color: '#666',
              cursor: 'pointer',
              fontSize: '14px'
            }}
          >
            {showPassword ? 'Hide' : 'Show'}
          </button>
        </div>
        {errors.password && <div className="error-message">{errors.password}</div>}
        <div className="help-text">
          Must be at least 8 characters with uppercase, lowercase, number, and special character
        </div>
      </div>
      
      <div className="form-group">
        <label htmlFor="confirmPassword">Confirm Password</label>
        <input
          type="password"
          id="confirmPassword"
          name="confirmPassword"
          value={formData.confirmPassword}
          onChange={handleChange}
          placeholder="••••••••"
          autoComplete="new-password"
        />
        {errors.confirmPassword && <div className="error-message">{errors.confirmPassword}</div>}
      </div>
      
      <div className="checkbox-group" style={{ marginTop: '24px' }}>
        <input
          type="checkbox"
          id="terms"
          defaultChecked
          disabled
        />
        <label htmlFor="terms" style={{ fontSize: '14px', color: '#999' }}>
          By creating an account, you agree to our{' '}
          <a 
            href="#" 
            onClick={(e) => {
              e.preventDefault();
              setShowTermsModal(true);
            }}
            style={{ color: '#4caf50' }}
          >
            Terms of Service
          </a>{' '}
          and{' '}
          <a 
            href="#" 
            onClick={(e) => {
              e.preventDefault();
              setShowPrivacyModal(true);
            }}
            style={{ color: '#4caf50' }}
          >
            Privacy Policy
          </a>
        </label>
      </div>
      
      {serverError && (
        <div className="error-message" style={{ marginBottom: '16px' }}>
          {serverError}
        </div>
      )}
      
      <div className="onboarding-screen-footer">
        <button 
          className="btn-primary" 
          onClick={handleSubmit}
          disabled={isSubmitting}
        >
          {isSubmitting ? 'Creating Account...' : 'Continue'}
        </button>
      </div>
      
      <LegalDocumentModal
        isOpen={showTermsModal}
        onClose={() => setShowTermsModal(false)}
        documentType="terms"
        title="Terms of Service"
      >
        <TermsOfServiceContent />
      </LegalDocumentModal>
      
      <LegalDocumentModal
        isOpen={showPrivacyModal}
        onClose={() => setShowPrivacyModal(false)}
        documentType="privacy"
        title="Privacy Policy"
      >
        <PrivacyPolicyContent />
      </LegalDocumentModal>
    </div>
  );
};

export default AccountCredentialsScreen;