import React, { useState } from 'react';

interface FinancialProfileScreenProps {
  onNext: (data: FinancialData) => void;
  data?: FinancialData;
}

interface FinancialData {
  annualIncome: string;
  netWorth: string;
  liquidNetWorth: string;
  investmentObjective: string;
  investmentExperience: string;
  riskTolerance: string;
  fundingSource: string[];
}

const FinancialProfileScreen: React.FC<FinancialProfileScreenProps> = ({ onNext, data }) => {
  const [formData] = useState<FinancialData>({
    annualIncome: data?.annualIncome || '',
    netWorth: data?.netWorth || '',
    liquidNetWorth: data?.liquidNetWorth || '',
    investmentObjective: data?.investmentObjective || '',
    investmentExperience: data?.investmentExperience || '',
    riskTolerance: data?.riskTolerance || '',
    fundingSource: data?.fundingSource || []
  });
  
  // TODO: Implement form handling
  // const [formData, setFormData] = useState<FinancialData>(...)
  
  const handleSubmit = () => {
    // TODO: Add validation
    onNext(formData);
  };
  
  return (
    <div className="screen-content">
      <h1>Financial Profile</h1>
      <p>Help us understand your financial situation and investment goals.</p>
      
      {/* TODO: Add form fields for financial information */}
      
      <div className="onboarding-screen-footer">
        <button className="btn-primary" onClick={handleSubmit}>
          Continue
        </button>
      </div>
    </div>
  );
};

export default FinancialProfileScreen;