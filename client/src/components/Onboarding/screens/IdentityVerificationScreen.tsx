import React, { useState } from 'react';

interface IdentityVerificationScreenProps {
  onNext: (data: IdentityData) => void;
  data?: IdentityData;
}

export interface IdentityData {
  ssn: string;
  taxIdType: string;
  employment: {
    status: string;
    employer?: string;
    occupation?: string;
  };
  publiclyTraded: boolean;
  publicCompany?: string;
  affiliatedExchange: boolean;
  affiliatedFirm?: string;
  politicallyExposed: boolean;
  familyExposed: boolean;
}

const IdentityVerificationScreen: React.FC<IdentityVerificationScreenProps> = ({ onNext, data }) => {
  // Generate test data for development
  const generateTestSSN = (): string => {
    // Generate a realistic but fake SSN (avoiding real patterns)
    const area = Math.floor(Math.random() * 899) + 100; // 100-999, avoiding 000
    const group = Math.floor(Math.random() * 99) + 1; // 01-99
    const serial = Math.floor(Math.random() * 9999) + 1; // 0001-9999
    return `${area}-${String(group).padStart(2, '0')}-${String(serial).padStart(4, '0')}`;
  };
  
  const generateTestData = (): Partial<IdentityData> => {
    const employmentOptions = [
      { status: 'employed', employer: 'Tech Solutions Inc.', occupation: 'Software Engineer' },
      { status: 'employed', employer: 'Global Marketing Corp', occupation: 'Marketing Manager' },
      { status: 'self_employed', employer: 'Freelance Consulting LLC', occupation: 'Business Consultant' },
      { status: 'employed', employer: 'Healthcare Partners', occupation: 'Physician' },
      { status: 'retired', employer: '', occupation: '' },
      { status: 'student', employer: '', occupation: '' }
    ];
    
    const employment = employmentOptions[Math.floor(Math.random() * employmentOptions.length)];
    
    return {
      ssn: generateTestSSN(),
      taxIdType: 'SSN',
      employment: {
        status: employment.status,
        employer: employment.employer,
        occupation: employment.occupation
      },
      publiclyTraded: false,
      affiliatedExchange: false,
      politicallyExposed: false,
      familyExposed: false
    };
  };
  
  const testData = data?.ssn ? {} : generateTestData();
  
  const [formData, setFormData] = useState<IdentityData>({
    ssn: data?.ssn || testData.ssn || '',
    taxIdType: data?.taxIdType || testData.taxIdType || 'SSN',
    employment: {
      status: data?.employment?.status || testData.employment?.status || '',
      employer: data?.employment?.employer || testData.employment?.employer || '',
      occupation: data?.employment?.occupation || testData.employment?.occupation || ''
    },
    publiclyTraded: data?.publiclyTraded || testData.publiclyTraded || false,
    publicCompany: data?.publicCompany || '',
    affiliatedExchange: data?.affiliatedExchange || testData.affiliatedExchange || false,
    affiliatedFirm: data?.affiliatedFirm || '',
    politicallyExposed: data?.politicallyExposed || testData.politicallyExposed || false,
    familyExposed: data?.familyExposed || testData.familyExposed || false
  });
  
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [showSSN, setShowSSN] = useState(false);
  
  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    const { name, value, type } = e.target;
    
    if (type === 'checkbox') {
      const checked = (e.target as HTMLInputElement).checked;
      setFormData(prev => ({ ...prev, [name]: checked }));
      
      // Clear related fields when unchecking
      if (!checked) {
        if (name === 'publiclyTraded') {
          setFormData(prev => ({ ...prev, publicCompany: '' }));
        } else if (name === 'affiliatedExchange') {
          setFormData(prev => ({ ...prev, affiliatedFirm: '' }));
        }
      }
    } else if (name.startsWith('employment.')) {
      const field = name.replace('employment.', '');
      setFormData(prev => ({
        ...prev,
        employment: {
          ...prev.employment,
          [field]: value
        }
      }));
    } else if (name === 'ssn') {
      // Format SSN as user types
      const cleaned = value.replace(/\D/g, '');
      const limited = cleaned.substring(0, 9);
      let formatted = limited;
      
      if (limited.length >= 6) {
        formatted = `${limited.slice(0, 3)}-${limited.slice(3, 5)}-${limited.slice(5)}`;
      } else if (limited.length >= 4) {
        formatted = `${limited.slice(0, 3)}-${limited.slice(3)}`;
      }
      
      setFormData(prev => ({ ...prev, ssn: formatted }));
    } else {
      setFormData(prev => ({ ...prev, [name]: value }));
    }
    
    // Clear error
    if (errors[name]) {
      setErrors(prev => ({ ...prev, [name]: '' }));
    }
  };
  
  const validateForm = (): boolean => {
    const newErrors: Record<string, string> = {};
    
    // SSN validation
    const ssnDigits = formData.ssn.replace(/\D/g, '');
    if (!ssnDigits) {
      newErrors.ssn = 'Social Security Number is required';
    } else if (ssnDigits.length !== 9) {
      newErrors.ssn = 'SSN must be 9 digits';
    } else if (ssnDigits === '000000000' || ssnDigits === '123456789') {
      newErrors.ssn = 'Please enter a valid SSN';
    }
    
    // Employment validation
    if (!formData.employment.status) {
      newErrors['employment.status'] = 'Employment status is required';
    }
    
    if (formData.employment.status === 'employed' || formData.employment.status === 'self_employed') {
      if (!formData.employment.employer?.trim()) {
        newErrors['employment.employer'] = 'Employer is required';
      }
      if (!formData.employment.occupation?.trim()) {
        newErrors['employment.occupation'] = 'Occupation is required';
      }
    }
    
    // Additional info validation
    if (formData.publiclyTraded && !formData.publicCompany?.trim()) {
      newErrors.publicCompany = 'Company name is required';
    }
    
    if (formData.affiliatedExchange && !formData.affiliatedFirm?.trim()) {
      newErrors.affiliatedFirm = 'Firm name is required';
    }
    
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };
  
  const handleSubmit = () => {
    if (validateForm()) {
      onNext(formData);
    }
  };
  
  const employmentStatuses = [
    { value: '', label: 'Select Status' },
    { value: 'employed', label: 'Employed' },
    { value: 'self_employed', label: 'Self-Employed' },
    { value: 'unemployed', label: 'Unemployed' },
    { value: 'retired', label: 'Retired' },
    { value: 'student', label: 'Student' }
  ];
  
  const showEmploymentDetails = ['employed', 'self_employed'].includes(formData.employment.status);
  
  return (
    <div className="screen-content">
      <div className="screen-header">
        <h2>Identity Verification</h2>
        <p>We're required by law to collect this information to verify your identity and comply with regulatory requirements.</p>
      </div>
      
      <div className="form-section">
        <h3>Tax Information</h3>
        
        <div className="form-group">
          <label htmlFor="taxIdType">Tax ID Type</label>
          <select
            id="taxIdType"
            name="taxIdType"
            value={formData.taxIdType}
            onChange={handleChange}
            className="form-control"
          >
            <option value="SSN">Social Security Number (SSN)</option>
            <option value="ITIN">Individual Taxpayer ID Number (ITIN)</option>
          </select>
        </div>
        
        <div className="form-group">
          <label htmlFor="ssn">
            {formData.taxIdType === 'SSN' ? 'Social Security Number' : 'ITIN'}
          </label>
          <div className="input-with-toggle">
            <input
              type={showSSN ? "text" : "password"}
              id="ssn"
              name="ssn"
              value={formData.ssn}
              onChange={handleChange}
              placeholder="XXX-XX-XXXX"
              className={errors.ssn ? 'error' : ''}
              autoComplete="off"
            />
            <button
              type="button"
              className="toggle-visibility"
              onClick={() => setShowSSN(!showSSN)}
              style={{
                position: 'absolute',
                right: '10px',
                top: '50%',
                transform: 'translateY(-50%)',
                background: 'none',
                border: 'none',
                cursor: 'pointer',
                padding: '4px',
                color: '#666'
              }}
            >
              {showSSN ? (
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                  <path d="M3 3L21 21" stroke="currentColor" strokeWidth="2" strokeLinecap="round"/>
                  <path d="M10.5 10.677C10.0656 11.136 9.81387 11.7403 9.81387 12.375C9.81387 13.6317 10.8683 14.6861 12.125 14.6861C12.7597 14.6861 13.364 14.4344 13.823 14" stroke="currentColor" strokeWidth="2" strokeLinecap="round"/>
                  <path d="M7.362 7.561C5.68 8.74 4.279 10.42 3 12C5.392 15.814 8.556 18.5 12 18.5C13.18 18.5 14.311 18.237 15.362 17.752" stroke="currentColor" strokeWidth="2" strokeLinecap="round"/>
                  <path d="M12 5.5C15.444 5.5 18.608 8.186 21 12C20.285 13.226 19.441 14.329 18.444 15.253" stroke="currentColor" strokeWidth="2" strokeLinecap="round"/>
                </svg>
              ) : (
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                  <circle cx="12" cy="12" r="3" stroke="currentColor" strokeWidth="2"/>
                  <path d="M21 12C21 12 18.5 5.5 12 5.5C5.5 5.5 3 12 3 12C3 12 5.5 18.5 12 18.5C18.5 18.5 21 12 21 12Z" stroke="currentColor" strokeWidth="2" strokeLinecap="round"/>
                </svg>
              )}
            </button>
          </div>
          {errors.ssn && <span className="error-message">{errors.ssn}</span>}
          <div className="help-text">This is encrypted and only used for identity verification</div>
        </div>
      </div>
      
      <div className="form-section">
        <h3>Employment Information</h3>
        
        <div className="form-group">
          <label htmlFor="employment.status">Employment Status</label>
          <select
            id="employment.status"
            name="employment.status"
            value={formData.employment.status}
            onChange={handleChange}
            className={errors['employment.status'] ? 'error' : ''}
          >
            {employmentStatuses.map(status => (
              <option key={status.value} value={status.value}>
                {status.label}
              </option>
            ))}
          </select>
          {errors['employment.status'] && <span className="error-message">{errors['employment.status']}</span>}
        </div>
        
        {showEmploymentDetails && (
          <>
            <div className="form-group">
              <label htmlFor="employment.employer">
                {formData.employment.status === 'self_employed' ? 'Company Name' : 'Employer'}
              </label>
              <input
                type="text"
                id="employment.employer"
                name="employment.employer"
                value={formData.employment.employer}
                onChange={handleChange}
                placeholder={formData.employment.status === 'self_employed' ? 'Your company name' : 'Employer name'}
                className={errors['employment.employer'] ? 'error' : ''}
              />
              {errors['employment.employer'] && <span className="error-message">{errors['employment.employer']}</span>}
            </div>
            
            <div className="form-group">
              <label htmlFor="employment.occupation">Occupation</label>
              <input
                type="text"
                id="employment.occupation"
                name="employment.occupation"
                value={formData.employment.occupation}
                onChange={handleChange}
                placeholder="e.g., Software Engineer, Teacher, Consultant"
                className={errors['employment.occupation'] ? 'error' : ''}
              />
              {errors['employment.occupation'] && <span className="error-message">{errors['employment.occupation']}</span>}
            </div>
          </>
        )}
      </div>
      
      <div className="form-section">
        <h3>Regulatory Disclosures</h3>
        <p className="section-description">We're required to ask these questions by financial regulations.</p>
        
        <div className="disclosure-group">
          <div className="checkbox-group">
            <input
              type="checkbox"
              id="publiclyTraded"
              name="publiclyTraded"
              checked={formData.publiclyTraded}
              onChange={handleChange}
            />
            <label htmlFor="publiclyTraded">
              I am a director, 10% shareholder, or policy-making officer of a publicly traded company
            </label>
          </div>
          
          {formData.publiclyTraded && (
            <div className="form-group indented">
              <label htmlFor="publicCompany">Company Name</label>
              <input
                type="text"
                id="publicCompany"
                name="publicCompany"
                value={formData.publicCompany}
                onChange={handleChange}
                placeholder="Enter company name"
                className={errors.publicCompany ? 'error' : ''}
              />
              {errors.publicCompany && <span className="error-message">{errors.publicCompany}</span>}
            </div>
          )}
        </div>
        
        <div className="disclosure-group">
          <div className="checkbox-group">
            <input
              type="checkbox"
              id="affiliatedExchange"
              name="affiliatedExchange"
              checked={formData.affiliatedExchange}
              onChange={handleChange}
            />
            <label htmlFor="affiliatedExchange">
              I am affiliated with a stock exchange or FINRA member firm
            </label>
          </div>
          
          {formData.affiliatedExchange && (
            <div className="form-group indented">
              <label htmlFor="affiliatedFirm">Firm Name</label>
              <input
                type="text"
                id="affiliatedFirm"
                name="affiliatedFirm"
                value={formData.affiliatedFirm}
                onChange={handleChange}
                placeholder="Enter firm name"
                className={errors.affiliatedFirm ? 'error' : ''}
              />
              {errors.affiliatedFirm && <span className="error-message">{errors.affiliatedFirm}</span>}
            </div>
          )}
        </div>
        
        <div className="disclosure-group">
          <div className="checkbox-group">
            <input
              type="checkbox"
              id="politicallyExposed"
              name="politicallyExposed"
              checked={formData.politicallyExposed}
              onChange={handleChange}
            />
            <label htmlFor="politicallyExposed">
              I am a senior political figure, senior government official, or senior military officer
            </label>
          </div>
        </div>
        
        <div className="disclosure-group">
          <div className="checkbox-group">
            <input
              type="checkbox"
              id="familyExposed"
              name="familyExposed"
              checked={formData.familyExposed}
              onChange={handleChange}
            />
            <label htmlFor="familyExposed">
              I have an immediate family member who is a senior political figure
            </label>
          </div>
        </div>
      </div>
      
      <style jsx>{`
        .form-section {
          margin-bottom: 32px;
        }
        
        .form-section h3 {
          font-size: 18px;
          margin-bottom: 16px;
          color: #fff;
        }
        
        .section-description {
          font-size: 14px;
          color: #999;
          margin-bottom: 20px;
        }
        
        .input-with-toggle {
          position: relative;
        }
        
        .disclosure-group {
          margin-bottom: 20px;
        }
        
        .indented {
          margin-left: 28px;
          margin-top: 12px;
        }
        
        .help-text {
          font-size: 12px;
          color: #888;
          margin-top: 4px;
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

export default IdentityVerificationScreen;