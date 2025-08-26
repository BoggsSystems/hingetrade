import React, { useState } from 'react';

interface IdentityVerificationScreenProps {
  onNext: (data: IdentityData) => void;
  data?: IdentityData;
}

interface IdentityData {
  ssn: string;
  citizenship: string;
  countryOfBirth: string;
  employmentStatus: string;
  employer?: string;
  jobTitle?: string;
}

const IdentityVerificationScreen: React.FC<IdentityVerificationScreenProps> = ({ onNext, data }) => {
  const [formData] = useState<IdentityData>({
    ssn: data?.ssn || '',
    citizenship: data?.citizenship || 'USA',
    countryOfBirth: data?.countryOfBirth || 'USA',
    employmentStatus: data?.employmentStatus || '',
    employer: data?.employer || '',
    jobTitle: data?.jobTitle || ''
  });
  
  // TODO: Implement form handling
  // const [errors, setErrors] = useState<Partial<IdentityData>>({});
  
  const handleSubmit = () => {
    // TODO: Add validation
    onNext(formData);
  };
  
  return (
    <div className="screen-content">
      <h1>Identity Verification</h1>
      <p>We need to verify your identity to comply with regulations.</p>
      
      {/* TODO: Add form fields for SSN, citizenship, employment info */}
      
      <div className="onboarding-screen-footer">
        <button className="btn-primary" onClick={handleSubmit}>
          Continue
        </button>
      </div>
    </div>
  );
};

export default IdentityVerificationScreen;