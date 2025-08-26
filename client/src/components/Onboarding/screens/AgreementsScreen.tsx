import React, { useState } from 'react';

interface AgreementsScreenProps {
  onNext: (data: AgreementsData) => void;
  data?: AgreementsData;
}

interface AgreementsData {
  customerAgreement: boolean;
  marginAgreement: boolean;
  riskDisclosure: boolean;
  dataSharing: boolean;
  timestamp: string;
  ipAddress: string;
}

const AgreementsScreen: React.FC<AgreementsScreenProps> = ({ onNext, data }) => {
  const [agreements] = useState<AgreementsData>({
    customerAgreement: data?.customerAgreement || false,
    marginAgreement: data?.marginAgreement || false,
    riskDisclosure: data?.riskDisclosure || false,
    dataSharing: data?.dataSharing || false,
    timestamp: new Date().toISOString(),
    ipAddress: '' // Would be set by backend
  });
  
  // TODO: Implement agreement handling
  // const [agreements, setAgreements] = useState<AgreementsData>(...)
  
  const handleSubmit = () => {
    // TODO: Add validation - all must be checked
    onNext(agreements);
  };
  
  return (
    <div className="screen-content">
      <h1>Account Agreements</h1>
      <p>Please review and accept the following agreements.</p>
      
      {/* TODO: Add agreement checkboxes and content */}
      
      <div className="onboarding-screen-footer">
        <button className="btn-primary" onClick={handleSubmit}>
          Continue
        </button>
      </div>
    </div>
  );
};

export default AgreementsScreen;