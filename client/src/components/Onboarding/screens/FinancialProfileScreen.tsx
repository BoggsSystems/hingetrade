import React, { useState } from 'react';

interface FinancialProfileScreenProps {
  onNext: (data: FinancialData) => void;
  data?: FinancialData;
}

export interface FinancialData {
  annualIncome: string;
  netWorth: string;
  liquidNetWorth: string;
  fundingSource: string;
  investmentObjective: string;
  investmentExperience: string;
  riskTolerance: string;
}

const FinancialProfileScreen: React.FC<FinancialProfileScreenProps> = ({ onNext, data }) => {
  // Generate test data for development
  const generateTestData = (): Partial<FinancialData> => {
    const incomeRanges = ['25000-50000', '50001-100000', '100001-200000', '200001-500000'];
    const netWorthRanges = ['0-25000', '25001-50000', '50001-100000', '100001-250000', '250001-500000'];
    const objectives = ['growth', 'income', 'capital_preservation', 'speculation'];
    const experience = ['none', 'limited', 'good', 'extensive'];
    const risk = ['conservative', 'moderate', 'aggressive'];
    const funding = ['employment', 'investments', 'business', 'retirement'];
    
    return {
      annualIncome: incomeRanges[Math.floor(Math.random() * incomeRanges.length)],
      netWorth: netWorthRanges[Math.floor(Math.random() * netWorthRanges.length)],
      liquidNetWorth: netWorthRanges[Math.floor(Math.random() * Math.floor(netWorthRanges.length / 2))],
      fundingSource: funding[Math.floor(Math.random() * funding.length)],
      investmentObjective: objectives[Math.floor(Math.random() * objectives.length)],
      investmentExperience: experience[Math.floor(Math.random() * experience.length)],
      riskTolerance: risk[Math.floor(Math.random() * risk.length)]
    };
  };
  
  const testData = data?.annualIncome ? {} : generateTestData();
  
  const [formData, setFormData] = useState<FinancialData>({
    annualIncome: data?.annualIncome || testData.annualIncome || '',
    netWorth: data?.netWorth || testData.netWorth || '',
    liquidNetWorth: data?.liquidNetWorth || testData.liquidNetWorth || '',
    fundingSource: data?.fundingSource || testData.fundingSource || '',
    investmentObjective: data?.investmentObjective || testData.investmentObjective || '',
    investmentExperience: data?.investmentExperience || testData.investmentExperience || '',
    riskTolerance: data?.riskTolerance || testData.riskTolerance || ''
  });
  
  const [errors, setErrors] = useState<Record<string, string>>({});
  
  const handleChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
    
    // Clear error
    if (errors[name]) {
      setErrors(prev => ({ ...prev, [name]: '' }));
    }
  };
  
  const validateForm = (): boolean => {
    const newErrors: Record<string, string> = {};
    
    if (!formData.annualIncome) {
      newErrors.annualIncome = 'Annual income is required';
    }
    if (!formData.netWorth) {
      newErrors.netWorth = 'Net worth is required';
    }
    if (!formData.liquidNetWorth) {
      newErrors.liquidNetWorth = 'Liquid net worth is required';
    }
    if (!formData.fundingSource) {
      newErrors.fundingSource = 'Funding source is required';
    }
    if (!formData.investmentObjective) {
      newErrors.investmentObjective = 'Investment objective is required';
    }
    if (!formData.investmentExperience) {
      newErrors.investmentExperience = 'Investment experience is required';
    }
    if (!formData.riskTolerance) {
      newErrors.riskTolerance = 'Risk tolerance is required';
    }
    
    // Validate liquid net worth <= net worth
    if (formData.liquidNetWorth && formData.netWorth) {
      const liquidValue = parseInt(formData.liquidNetWorth.split('-')[1] || '0');
      const netValue = parseInt(formData.netWorth.split('-')[0] || '0');
      
      if (liquidValue > netValue) {
        newErrors.liquidNetWorth = 'Liquid net worth cannot exceed total net worth';
      }
    }
    
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };
  
  const handleSubmit = () => {
    if (validateForm()) {
      onNext(formData);
    }
  };
  
  const incomeRanges = [
    { value: '', label: 'Select Annual Income' },
    { value: '0-25000', label: '$0 - $25,000' },
    { value: '25001-50000', label: '$25,001 - $50,000' },
    { value: '50001-100000', label: '$50,001 - $100,000' },
    { value: '100001-200000', label: '$100,001 - $200,000' },
    { value: '200001-500000', label: '$200,001 - $500,000' },
    { value: '500001-1000000', label: '$500,001 - $1,000,000' },
    { value: '1000000+', label: 'Over $1,000,000' }
  ];
  
  const netWorthRanges = [
    { value: '', label: 'Select Net Worth' },
    { value: '0-25000', label: '$0 - $25,000' },
    { value: '25001-50000', label: '$25,001 - $50,000' },
    { value: '50001-100000', label: '$50,001 - $100,000' },
    { value: '100001-250000', label: '$100,001 - $250,000' },
    { value: '250001-500000', label: '$250,001 - $500,000' },
    { value: '500001-1000000', label: '$500,001 - $1,000,000' },
    { value: '1000001-5000000', label: '$1,000,001 - $5,000,000' },
    { value: '5000000+', label: 'Over $5,000,000' }
  ];
  
  const fundingSources = [
    { value: '', label: 'Select Primary Source' },
    { value: 'employment', label: 'Employment Income' },
    { value: 'investments', label: 'Investment Returns' },
    { value: 'inheritance', label: 'Inheritance or Gift' },
    { value: 'business', label: 'Business Income' },
    { value: 'retirement', label: 'Retirement/Pension' },
    { value: 'real_estate', label: 'Real Estate' },
    { value: 'other', label: 'Other' }
  ];
  
  const objectives = [
    { value: '', label: 'Select Investment Objective' },
    { value: 'capital_preservation', label: 'Capital Preservation' },
    { value: 'income', label: 'Income Generation' },
    { value: 'growth', label: 'Growth' },
    { value: 'speculation', label: 'Speculation' },
    { value: 'other', label: 'Other' }
  ];
  
  const experienceLevels = [
    { value: '', label: 'Select Experience Level' },
    { value: 'none', label: 'None (New to investing)' },
    { value: 'limited', label: 'Limited (Less than 2 years)' },
    { value: 'good', label: 'Good (2-5 years)' },
    { value: 'extensive', label: 'Extensive (Over 5 years)' }
  ];
  
  const riskLevels = [
    { value: '', label: 'Select Risk Tolerance' },
    { value: 'conservative', label: 'Conservative (Low risk, low return)' },
    { value: 'moderate', label: 'Moderate (Balanced risk and return)' },
    { value: 'aggressive', label: 'Aggressive (High risk, high return)' }
  ];
  
  return (
    <div className="screen-content">
      <div className="screen-header">
        <h2>Financial Profile</h2>
        <p>Help us understand your financial situation and investment goals. This information is required by regulations and helps ensure suitable investment recommendations.</p>
      </div>
      
      <div className="form-section">
        <h3>Financial Information</h3>
        
        <div className="form-group">
          <label htmlFor="annualIncome">Annual Income</label>
          <select
            id="annualIncome"
            name="annualIncome"
            value={formData.annualIncome}
            onChange={handleChange}
            className={errors.annualIncome ? 'error' : ''}
          >
            {incomeRanges.map(range => (
              <option key={range.value} value={range.value}>
                {range.label}
              </option>
            ))}
          </select>
          {errors.annualIncome && <span className="error-message">{errors.annualIncome}</span>}
          <div className="help-text">Your total pre-tax income from all sources</div>
        </div>
        
        <div className="form-row">
          <div className="form-group">
            <label htmlFor="netWorth">Total Net Worth</label>
            <select
              id="netWorth"
              name="netWorth"
              value={formData.netWorth}
              onChange={handleChange}
              className={errors.netWorth ? 'error' : ''}
            >
              {netWorthRanges.map(range => (
                <option key={range.value} value={range.value}>
                  {range.label}
                </option>
              ))}
            </select>
            {errors.netWorth && <span className="error-message">{errors.netWorth}</span>}
            <div className="help-text">Total assets minus total liabilities</div>
          </div>
          
          <div className="form-group">
            <label htmlFor="liquidNetWorth">Liquid Net Worth</label>
            <select
              id="liquidNetWorth"
              name="liquidNetWorth"
              value={formData.liquidNetWorth}
              onChange={handleChange}
              className={errors.liquidNetWorth ? 'error' : ''}
            >
              {netWorthRanges.map(range => (
                <option key={range.value} value={range.value}>
                  {range.label}
                </option>
              ))}
            </select>
            {errors.liquidNetWorth && <span className="error-message">{errors.liquidNetWorth}</span>}
            <div className="help-text">Assets easily converted to cash</div>
          </div>
        </div>
        
        <div className="form-group">
          <label htmlFor="fundingSource">Primary Source of Funds</label>
          <select
            id="fundingSource"
            name="fundingSource"
            value={formData.fundingSource}
            onChange={handleChange}
            className={errors.fundingSource ? 'error' : ''}
          >
            {fundingSources.map(source => (
              <option key={source.value} value={source.value}>
                {source.label}
              </option>
            ))}
          </select>
          {errors.fundingSource && <span className="error-message">{errors.fundingSource}</span>}
          <div className="help-text">Where will your investment funds come from?</div>
        </div>
      </div>
      
      <div className="form-section">
        <h3>Investment Profile</h3>
        
        <div className="form-group">
          <label htmlFor="investmentObjective">Investment Objective</label>
          <select
            id="investmentObjective"
            name="investmentObjective"
            value={formData.investmentObjective}
            onChange={handleChange}
            className={errors.investmentObjective ? 'error' : ''}
          >
            {objectives.map(obj => (
              <option key={obj.value} value={obj.value}>
                {obj.label}
              </option>
            ))}
          </select>
          {errors.investmentObjective && <span className="error-message">{errors.investmentObjective}</span>}
          <div className="help-text">Your primary goal for investing</div>
        </div>
        
        <div className="form-row">
          <div className="form-group">
            <label htmlFor="investmentExperience">Investment Experience</label>
            <select
              id="investmentExperience"
              name="investmentExperience"
              value={formData.investmentExperience}
              onChange={handleChange}
              className={errors.investmentExperience ? 'error' : ''}
            >
              {experienceLevels.map(level => (
                <option key={level.value} value={level.value}>
                  {level.label}
                </option>
              ))}
            </select>
            {errors.investmentExperience && <span className="error-message">{errors.investmentExperience}</span>}
          </div>
          
          <div className="form-group">
            <label htmlFor="riskTolerance">Risk Tolerance</label>
            <select
              id="riskTolerance"
              name="riskTolerance"
              value={formData.riskTolerance}
              onChange={handleChange}
              className={errors.riskTolerance ? 'error' : ''}
            >
              {riskLevels.map(level => (
                <option key={level.value} value={level.value}>
                  {level.label}
                </option>
              ))}
            </select>
            {errors.riskTolerance && <span className="error-message">{errors.riskTolerance}</span>}
          </div>
        </div>
      </div>
      
      <div className="info-box">
        <h4>
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" style={{ display: 'inline-block', verticalAlign: 'middle', marginRight: '8px' }}>
            <circle cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="1.5"/>
            <path d="M12 16V12M12 8H12.01" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round"/>
          </svg>
          Why we need this information
        </h4>
        <p>Financial regulators require us to collect this information to ensure investment recommendations are suitable for your financial situation. This helps protect you from taking on inappropriate levels of risk.</p>
      </div>
      
      <style>{`
        .form-section {
          margin-bottom: 32px;
        }
        
        .form-section h3 {
          font-size: 18px;
          margin-bottom: 16px;
          color: #fff;
        }
        
        .help-text {
          font-size: 12px;
          color: #888;
          margin-top: 4px;
        }
        
        .info-box {
          background-color: #1a1a1a;
          border: 1px solid #2a2a2a;
          border-radius: 8px;
          padding: 20px;
          margin-top: 24px;
        }
        
        .info-box h4 {
          margin: 0 0 12px 0;
          color: #e5e5e5;
          font-size: 16px;
        }
        
        .info-box p {
          margin: 0;
          color: #9ca3af;
          font-size: 14px;
          line-height: 1.5;
        }
        
        .form-row {
          display: grid;
          grid-template-columns: 1fr 1fr;
          gap: 16px;
        }
        
        @media (max-width: 768px) {
          .form-row {
            grid-template-columns: 1fr;
          }
        }
      `}</style>
      
      <div className="screen-actions">
        <button 
          className="btn-primary" 
          onClick={handleSubmit}
        >
          Continue
        </button>
      </div>
    </div>
  );
};

export default FinancialProfileScreen;