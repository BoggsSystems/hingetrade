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
          <div className="feature-icon">📋</div>
          <div className="feature-text">
            <h3>Personal Information</h3>
            <p>We'll collect your basic information and verify your identity as required by law.</p>
          </div>
        </div>
        
        <div className="feature-item">
          <div className="feature-icon">📄</div>
          <div className="feature-text">
            <h3>Document Upload</h3>
            <p>Upload a photo of your ID to verify your identity.</p>
          </div>
        </div>
        
        <div className="feature-item">
          <div className="feature-icon">💰</div>
          <div className="feature-text">
            <h3>Financial Profile</h3>
            <p>Tell us about your investment experience and objectives.</p>
          </div>
        </div>
        
        <div className="feature-item">
          <div className="feature-icon">🏦</div>
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