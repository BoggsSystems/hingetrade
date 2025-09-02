'use client';

import { useState, useEffect } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import './Modal.css';

interface RegistrationModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess?: () => void;
  onSwitchToLogin?: () => void;
  redirectTo?: string | null;
}

export default function RegistrationModal({ isOpen, onClose, onSuccess, onSwitchToLogin, redirectTo }: RegistrationModalProps) {
  const [formData, setFormData] = useState({
    firstName: '',
    lastName: '',
    email: '',
    password: '',
    confirmPassword: '',
    agreeToTerms: false,
  });
  
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [isLoading, setIsLoading] = useState(false);
  const { register } = useAuth();

  // Reset form when modal opens/closes
  useEffect(() => {
    if (isOpen) {
      setFormData({
        firstName: '',
        lastName: '',
        email: '',
        password: '',
        confirmPassword: '',
        agreeToTerms: false,
      });
      setErrors({});
    }
  }, [isOpen]);

  // Handle escape key
  useEffect(() => {
    const handleEscape = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && isOpen) {
        onClose();
      }
    };

    if (isOpen) {
      document.addEventListener('keydown', handleEscape);
      document.body.style.overflow = 'hidden';
    }

    return () => {
      document.removeEventListener('keydown', handleEscape);
      document.body.style.overflow = 'unset';
    };
  }, [isOpen, onClose]);

  if (!isOpen) return null;

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value, type, checked } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: type === 'checkbox' ? checked : value,
    }));

    // Clear error when user starts typing
    if (errors[name]) {
      setErrors(prev => ({ ...prev, [name]: '' }));
    }
  };

  const validateForm = () => {
    const newErrors: Record<string, string> = {};

    if (!formData.firstName.trim()) {
      newErrors.firstName = 'First name is required';
    }

    if (!formData.lastName.trim()) {
      newErrors.lastName = 'Last name is required';
    }

    if (!formData.email.trim()) {
      newErrors.email = 'Email is required';
    } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(formData.email)) {
      newErrors.email = 'Please enter a valid email address';
    }

    if (!formData.password) {
      newErrors.password = 'Password is required';
    } else if (formData.password.length < 8) {
      newErrors.password = 'Password must be at least 8 characters long';
    }

    if (formData.password !== formData.confirmPassword) {
      newErrors.confirmPassword = 'Passwords do not match';
    }

    if (!formData.agreeToTerms) {
      newErrors.agreeToTerms = 'You must agree to the terms and conditions';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!validateForm()) {
      return;
    }

    setIsLoading(true);

    try {
      await register(formData.email, formData.firstName, formData.lastName, formData.password, redirectTo || undefined);
      onSuccess?.();
      onClose();
    } catch (error: any) {
      setErrors({ submit: error.message || 'Registration failed. Please try again.' });
    } finally {
      setIsLoading(false);
    }
  };

  const handleOverlayClick = (e: React.MouseEvent) => {
    if (e.target === e.currentTarget) {
      onClose();
    }
  };

  return (
    <div className="modal-overlay" onClick={handleOverlayClick}>
      <div className="modal-container registration">
        <div className="modal-header">
          <div>
            <h2>Create Your Account</h2>
            <p className="modal-subtitle">Join thousands of creators monetizing their trading expertise</p>
          </div>
          <button className="modal-close-button" onClick={onClose} type="button">
            ×
          </button>
        </div>

        <div className="modal-content">
          <form onSubmit={handleSubmit} className="modal-form">
            {errors.submit && (
              <div className="modal-error-message">
                <svg width="16" height="16" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clipRule="evenodd" />
                </svg>
                <span>{errors.submit}</span>
              </div>
            )}

            <div className="modal-form-row">
              <div className="modal-form-group">
                <label htmlFor="firstName">First Name</label>
                <input
                  id="firstName"
                  name="firstName"
                  type="text"
                  value={formData.firstName}
                  onChange={handleInputChange}
                  placeholder="Enter your first name"
                  disabled={isLoading}
                />
                {errors.firstName && (
                  <div className="modal-help-text" style={{ color: 'var(--color-negative)' }}>
                    {errors.firstName}
                  </div>
                )}
              </div>
              
              <div className="modal-form-group">
                <label htmlFor="lastName">Last Name</label>
                <input
                  id="lastName"
                  name="lastName"
                  type="text"
                  value={formData.lastName}
                  onChange={handleInputChange}
                  placeholder="Enter your last name"
                  disabled={isLoading}
                />
                {errors.lastName && (
                  <div className="modal-help-text" style={{ color: 'var(--color-negative)' }}>
                    {errors.lastName}
                  </div>
                )}
              </div>
            </div>

            <div className="modal-form-group">
              <label htmlFor="email">Email Address</label>
              <input
                id="email"
                name="email"
                type="email"
                value={formData.email}
                onChange={handleInputChange}
                placeholder="Enter your email address"
                disabled={isLoading}
              />
              {errors.email && (
                <div className="modal-help-text" style={{ color: 'var(--color-negative)' }}>
                  {errors.email}
                </div>
              )}
            </div>

            <div className="modal-form-group">
              <label htmlFor="password">Password</label>
              <input
                id="password"
                name="password"
                type="password"
                value={formData.password}
                onChange={handleInputChange}
                placeholder="Create a strong password"
                disabled={isLoading}
              />
              <div className="modal-help-text">
                <svg width="12" height="12" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clipRule="evenodd" />
                </svg>
                Must be at least 8 characters long
              </div>
              {errors.password && (
                <div className="modal-help-text" style={{ color: 'var(--color-negative)' }}>
                  {errors.password}
                </div>
              )}
            </div>

            <div className="modal-form-group">
              <label htmlFor="confirmPassword">Confirm Password</label>
              <input
                id="confirmPassword"
                name="confirmPassword"
                type="password"
                value={formData.confirmPassword}
                onChange={handleInputChange}
                placeholder="Confirm your password"
                disabled={isLoading}
              />
              {errors.confirmPassword && (
                <div className="modal-help-text" style={{ color: 'var(--color-negative)' }}>
                  {errors.confirmPassword}
                </div>
              )}
            </div>

            <div className="modal-checkbox-group">
              <input
                id="agreeToTerms"
                name="agreeToTerms"
                type="checkbox"
                checked={formData.agreeToTerms}
                onChange={handleInputChange}
                disabled={isLoading}
              />
              <label htmlFor="agreeToTerms">
                I agree to the{' '}
                <a href="/terms" className="modal-link" target="_blank" rel="noopener noreferrer" style={{ color: 'var(--color-positive)' }}>
                  Terms of Service
                </a>
                {' '}and{' '}
                <a href="/privacy" className="modal-link" target="_blank" rel="noopener noreferrer" style={{ color: 'var(--color-positive)' }}>
                  Privacy Policy
                </a>
              </label>
            </div>
            {errors.agreeToTerms && (
              <div className="modal-help-text" style={{ color: 'var(--color-negative)', marginTop: '-12px' }}>
                {errors.agreeToTerms}
              </div>
            )}
          </form>
        </div>

        <div className="modal-controls">
          <div className="modal-controls-left">
            <button
              type="button"
              className="modal-btn modal-btn-ghost"
              onClick={onClose}
              disabled={isLoading}
            >
              Cancel
            </button>
          </div>
          
          <div className="modal-controls-right">
            <button
              type="submit"
              className="modal-btn modal-btn-primary"
              onClick={handleSubmit}
              disabled={isLoading || !formData.agreeToTerms}
            >
              {isLoading ? (
                <>
                  <span className="spinner"></span>
                  Creating Account...
                </>
              ) : (
                <>
                  <svg width="16" height="16" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z" />
                  </svg>
                  Create Account
                </>
              )}
            </button>
          </div>
        </div>

        {/* Footer with login link */}
        <div style={{ 
          padding: '16px 24px', 
          borderTop: '1px solid var(--color-border)',
          textAlign: 'center',
          fontSize: '14px'
        }}>
          <span style={{ color: 'var(--color-text-secondary)' }}>
            Already have an account?{' '}
          </span>
          <button
            type="button"
            onClick={onSwitchToLogin}
            style={{
              background: 'none',
              border: 'none',
              color: 'var(--color-primary)',
              cursor: 'pointer',
              textDecoration: 'underline',
              fontSize: 'inherit',
              padding: '0'
            }}
            disabled={isLoading}
          >
            Sign in
          </button>
        </div>
      </div>
    </div>
  );
}