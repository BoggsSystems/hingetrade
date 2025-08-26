import React from 'react';

interface SubmissionSuccessScreenProps {
  onContinue: () => void;
}

const SubmissionSuccessScreen: React.FC<SubmissionSuccessScreenProps> = () => {
  return (
    <div className="screen-content submission-success">
      <div className="success-icon">
        <svg 
          width="80" 
          height="80" 
          viewBox="0 0 80 80" 
          fill="none" 
          xmlns="http://www.w3.org/2000/svg"
        >
          <circle cx="40" cy="40" r="40" fill="#10B981" fillOpacity="0.1"/>
          <path 
            d="M55 30L33 52L25 44" 
            stroke="#10B981" 
            strokeWidth="4" 
            strokeLinecap="round" 
            strokeLinejoin="round"
          />
        </svg>
      </div>
      
      <h1>Application Submitted Successfully!</h1>
      
      <div className="success-message">
        <p>Thank you for completing your application. We've received all your information and it's now under review.</p>
        
        <div className="info-box">
          <h4>What happens next?</h4>
          <ul>
            <li>Your application is being reviewed by our team</li>
            <li>This typically takes 1-2 business days</li>
            <li>You'll receive an email once your account is approved</li>
            <li>You can check your application status anytime from your dashboard</li>
          </ul>
        </div>
        
        <p className="note">
          <strong>Note:</strong> In sandbox mode, your application will be automatically approved within 5 seconds for testing purposes.
        </p>
      </div>
      
      <div className="onboarding-screen-footer">
        <button className="btn-primary" onClick={() => {
          // Redirect to landing page after successful submission
          window.location.href = '/';
        }}>
          Return to Home
        </button>
      </div>
    </div>
  );
};

export default SubmissionSuccessScreen;