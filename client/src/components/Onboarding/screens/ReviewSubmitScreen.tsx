import React from 'react';
import type { KYCData } from '../../../pages/Onboarding/OnboardingPage';

interface ReviewSubmitScreenProps {
  kycData: KYCData;
  onSubmit: () => void;
  onEdit: (step: number) => void;
  isSubmitting?: boolean;
}

const ReviewSubmitScreen: React.FC<ReviewSubmitScreenProps> = ({ 
  kycData, 
  onSubmit, 
  onEdit,
  isSubmitting = false
}) => {
  return (
    <div className="screen-content">
      <h1>Review and Submit</h1>
      <p>Please review your information before submitting your application.</p>
      
      <div className="review-section">
        <h3>
          Personal Information
          <span className="edit-link" onClick={() => onEdit(1)}>Edit</span>
        </h3>
        {kycData.personalInfo && (
          <>
            <div className="review-item">
              <span className="review-label">Name</span>
              <span className="review-value">
                {kycData.personalInfo.firstName} {kycData.personalInfo.lastName}
              </span>
            </div>
            <div className="review-item">
              <span className="review-label">Date of Birth</span>
              <span className="review-value">{kycData.personalInfo.dateOfBirth}</span>
            </div>
            <div className="review-item">
              <span className="review-label">Phone</span>
              <span className="review-value">{kycData.personalInfo.phoneNumber}</span>
            </div>
            <div className="review-item">
              <span className="review-label">Email</span>
              <span className="review-value">{kycData.personalInfo.email}</span>
            </div>
          </>
        )}
      </div>
      
      <div className="review-section">
        <h3>
          Address
          <span className="edit-link" onClick={() => onEdit(2)}>Edit</span>
        </h3>
        {kycData.address && (
          <>
            <div className="review-item">
              <span className="review-label">Street</span>
              <span className="review-value">
                {kycData.address.streetAddress}
                {kycData.address.streetAddress2 && `, ${kycData.address.streetAddress2}`}
              </span>
            </div>
            <div className="review-item">
              <span className="review-label">City, State, ZIP</span>
              <span className="review-value">
                {kycData.address.city}, {kycData.address.state} {kycData.address.zipCode}
              </span>
            </div>
          </>
        )}
      </div>
      
      <div className="review-section">
        <h3>
          Identity & Employment
          <span className="edit-link" onClick={() => onEdit(3)}>Edit</span>
        </h3>
        {kycData.identity && (
          <>
            <div className="review-item">
              <span className="review-label">SSN</span>
              <span className="review-value">***-**-{kycData.identity.ssn.slice(-4)}</span>
            </div>
            <div className="review-item">
              <span className="review-label">Tax ID Type</span>
              <span className="review-value">{kycData.identity.taxIdType}</span>
            </div>
            <div className="review-item">
              <span className="review-label">Employment</span>
              <span className="review-value">{kycData.identity.employment.status}</span>
            </div>
          </>
        )}
      </div>
      
      <div className="help-text" style={{ marginTop: '32px' }}>
        <p style={{ fontSize: '14px', color: '#888' }}>
          By clicking Submit, you confirm that all information provided is accurate and complete. 
          Your application will be reviewed and you'll receive an email once it's processed.
        </p>
      </div>
      
      <div className="onboarding-screen-footer">
        <button 
          className="btn-primary" 
          onClick={onSubmit}
          disabled={isSubmitting}
        >
          {isSubmitting ? (
            <>
              <span className="spinner" /> Submitting...
            </>
          ) : (
            'Submit Application'
          )}
        </button>
      </div>
    </div>
  );
};

export default ReviewSubmitScreen;