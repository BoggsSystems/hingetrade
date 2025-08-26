import React from 'react';

interface SubmissionErrorScreenProps {
  error: string;
  onRetry: () => void;
  onClose: () => void;
}

const SubmissionErrorScreen: React.FC<SubmissionErrorScreenProps> = ({ 
  error, 
  onRetry, 
  onClose 
}) => {
  // Parse common error types
  const getErrorDetails = () => {
    if (error.toLowerCase().includes('network') || error.toLowerCase().includes('fetch')) {
      return {
        title: 'Connection Error',
        message: 'Unable to connect to our servers. Please check your internet connection and try again.',
        icon: '🌐'
      };
    }
    
    if (error.toLowerCase().includes('timeout')) {
      return {
        title: 'Request Timeout',
        message: 'The request took too long to complete. Please try again.',
        icon: '⏱️'
      };
    }
    
    if (error.toLowerCase().includes('validation')) {
      return {
        title: 'Validation Error',
        message: 'Some of the information provided is invalid. Please review your details and try again.',
        icon: '⚠️'
      };
    }
    
    return {
      title: 'Submission Failed',
      message: error || 'An unexpected error occurred while submitting your application.',
      icon: '❌'
    };
  };
  
  const errorDetails = getErrorDetails();
  
  return (
    <div className="screen-content submission-error">
      <div className="error-icon">
        <span style={{ fontSize: '48px' }}>{errorDetails.icon}</span>
      </div>
      
      <h1>{errorDetails.title}</h1>
      
      <div className="error-message">
        <p>{errorDetails.message}</p>
        
        <div className="error-details">
          <details>
            <summary>Technical Details</summary>
            <pre>{error}</pre>
          </details>
        </div>
        
        <div className="help-text">
          <h4>Need help?</h4>
          <p>If this problem persists, please contact our support team at support@hingetrade.com</p>
        </div>
      </div>
      
      <div className="onboarding-screen-footer">
        <button className="btn-secondary" onClick={onClose}>
          Save & Exit
        </button>
        <button className="btn-primary" onClick={onRetry}>
          Try Again
        </button>
      </div>
    </div>
  );
};

export default SubmissionErrorScreen;