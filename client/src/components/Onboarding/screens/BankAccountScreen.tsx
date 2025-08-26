import React, { useState } from 'react';

interface BankAccountScreenProps {
  onNext: (data: BankAccountData) => void;
  data?: BankAccountData;
}

interface BankAccountData {
  method: 'ach' | 'wire';
  achDetails?: {
    accountNumber: string;
    routingNumber: string;
    accountType: 'checking' | 'savings';
    bankName: string;
  };
}

const BankAccountScreen: React.FC<BankAccountScreenProps> = ({ onNext, data }) => {
  const [formData] = useState<BankAccountData>({
    method: data?.method || 'ach',
    achDetails: data?.achDetails
  });
  
  // TODO: Implement form handling
  // const [formData, setFormData] = useState<BankAccountData>(...)
  
  const handleSubmit = () => {
    // TODO: Add validation
    onNext(formData);
  };
  
  return (
    <div className="screen-content">
      <h1>Bank Account</h1>
      <p>Link your bank account to fund your trading account.</p>
      
      {/* TODO: Add bank account linking interface */}
      
      <div className="onboarding-screen-footer">
        <button className="btn-primary" onClick={handleSubmit}>
          Continue
        </button>
      </div>
    </div>
  );
};

export default BankAccountScreen;