import React from 'react';

interface WelcomeScreenProps {
  onNext: () => void;
}

const WelcomeScreen: React.FC<WelcomeScreenProps> = ({ onNext }) => {
  return (
    <div className="screen-content">
      <h1>Open Your Trading Account</h1>
      <p>
        Welcome to HingeTrade! We'll guide you through the account opening process. 
        This typically takes 5-10 minutes to complete.
      </p>
      
      <div className="feature-list">
        <div className="feature-item">
          <div className="feature-icon">
            <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
              <rect x="5" y="3" width="14" height="18" rx="2" stroke="currentColor" strokeWidth="1.5"/>
              <path d="M9 7H15" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round"/>
              <path d="M9 11H15" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round"/>
              <path d="M9 15H12" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round"/>
            </svg>
          </div>
          <div className="feature-text">
            <h3>Personal Information</h3>
            <p>We'll collect your basic information and verify your identity as required by law.</p>
          </div>
        </div>
        
        <div className="feature-item">
          <div className="feature-icon">
            <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
              <path d="M14 2H6C5.448 2 5 2.448 5 3V21C5 21.552 5.448 22 6 22H18C18.552 22 19 21.552 19 21V7L14 2Z" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
              <path d="M14 2V7H19" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
              <path d="M12 18V12" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round"/>
              <path d="M9 15L12 12L15 15" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
          </div>
          <div className="feature-text">
            <h3>Document Upload</h3>
            <p>Upload a photo of your ID to verify your identity.</p>
          </div>
        </div>
        
        <div className="feature-item">
          <div className="feature-icon">
            <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
              <circle cx="12" cy="12" r="9" stroke="currentColor" strokeWidth="1.5"/>
              <path d="M12 6V12L16 14" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round"/>
              <path d="M8.5 9.5C8.5 9.5 9.5 8 12 8C14.5 8 15.5 9.5 15.5 11C15.5 12.5 14 13.5 12 14V16" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round"/>
            </svg>
          </div>
          <div className="feature-text">
            <h3>Financial Profile</h3>
            <p>Tell us about your investment experience and objectives.</p>
          </div>
        </div>
        
        <div className="feature-item">
          <div className="feature-icon">
            <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
              <rect x="3" y="6" width="18" height="12" rx="2" stroke="currentColor" strokeWidth="1.5"/>
              <path d="M3 10H21" stroke="currentColor" strokeWidth="1.5"/>
              <path d="M7 15H10" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round"/>
              <path d="M7 2L7 6" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round"/>
              <path d="M17 2L17 6" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round"/>
            </svg>
          </div>
          <div className="feature-text">
            <h3>Bank Account</h3>
            <p>Link your bank account to fund your trading account.</p>
          </div>
        </div>
      </div>
      
      <div className="help-text" style={{ marginTop: '32px' }}>
        <p style={{ fontSize: '14px', color: '#888' }}>
          <strong>Note:</strong> We take your privacy seriously. All information is encrypted 
          and securely stored. We will never share your personal information without your consent.
        </p>
      </div>
      
      <div className="onboarding-screen-footer">
        <button className="btn-primary" onClick={onNext}>
          Get Started
        </button>
      </div>
    </div>
  );
};

export default WelcomeScreen;