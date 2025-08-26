import React, { useState } from 'react';

interface AgreementsScreenProps {
  onNext: (data: AgreementsData) => void;
  data?: AgreementsData;
}

export interface AgreementsData {
  customerAgreement: boolean;
  marketDataAgreement: boolean;
  privacyPolicy: boolean;
  communicationConsent: boolean;
  w9Certification: boolean;
}

const AgreementsScreen: React.FC<AgreementsScreenProps> = ({ onNext, data }) => {
  const [agreements, setAgreements] = useState<AgreementsData>({
    customerAgreement: data?.customerAgreement || false,
    marketDataAgreement: data?.marketDataAgreement || false,
    privacyPolicy: data?.privacyPolicy || false,
    communicationConsent: data?.communicationConsent || false,
    w9Certification: data?.w9Certification || false
  });
  
  const [expandedAgreements, setExpandedAgreements] = useState<Set<string>>(new Set());
  const [errors, setErrors] = useState<Record<string, string>>({});
  
  const handleCheckboxChange = (agreementKey: keyof AgreementsData) => {
    setAgreements(prev => ({
      ...prev,
      [agreementKey]: !prev[agreementKey]
    }));
    
    // Clear error if checking required agreement
    if (errors[agreementKey]) {
      setErrors(prev => ({ ...prev, [agreementKey]: '' }));
    }
  };
  
  const toggleExpanded = (agreementKey: string) => {
    setExpandedAgreements(prev => {
      const newSet = new Set(prev);
      if (newSet.has(agreementKey)) {
        newSet.delete(agreementKey);
      } else {
        newSet.add(agreementKey);
      }
      return newSet;
    });
  };
  
  const validateForm = (): boolean => {
    const newErrors: Record<string, string> = {};
    
    if (!agreements.customerAgreement) {
      newErrors.customerAgreement = 'You must accept the Customer Account Agreement';
    }
    if (!agreements.marketDataAgreement) {
      newErrors.marketDataAgreement = 'You must accept the Market Data Agreement';
    }
    if (!agreements.privacyPolicy) {
      newErrors.privacyPolicy = 'You must accept the Privacy Policy';
    }
    if (!agreements.w9Certification) {
      newErrors.w9Certification = 'You must complete the W-9 Certification';
    }
    // Note: communicationConsent is optional
    
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };
  
  const handleSubmit = () => {
    if (validateForm()) {
      onNext(agreements);
    }
  };
  
  // Agreement content (shortened for display, would be full text in production)
  const agreementContent = {
    customerAgreement: {
      title: 'Customer Account Agreement',
      required: true,
      content: `
CUSTOMER ACCOUNT AGREEMENT

This Agreement is entered into between you ("Customer," "you," or "your") and Alpaca Securities LLC ("Alpaca," "we," "us," or "our"), a registered broker-dealer and member of FINRA and SIPC.

1. ACCOUNT OPENING AND MAINTENANCE
By opening an account with Alpaca, you agree to be bound by the terms and conditions of this Agreement. You represent that the information provided in your account application is true, complete, and accurate.

2. TRADING AUTHORIZATION
You authorize Alpaca to accept and execute orders for the purchase and sale of securities in your account. All transactions will be subject to the rules and regulations of the applicable exchanges and regulatory authorities.

3. SETTLEMENT AND CLEARING
All transactions will be cleared and settled through our clearing firm. You agree to pay for all securities purchased by the settlement date and to deliver all securities sold by the settlement date.

4. FEES AND COMMISSIONS
You agree to pay all applicable fees, commissions, and charges as published on our website and updated from time to time. Alpaca reserves the right to change fees with 30 days' notice.

5. ACCOUNT SECURITY
You are responsible for maintaining the security of your account credentials. You agree to notify us immediately of any unauthorized access to your account.

6. LIMITATION OF LIABILITY
Alpaca shall not be liable for any losses resulting from market conditions, system failures, or other circumstances beyond our reasonable control.

7. ARBITRATION AGREEMENT
Any controversy or claim arising out of or relating to this Agreement shall be settled by arbitration in accordance with the rules of FINRA.

8. GOVERNING LAW
This Agreement shall be governed by the laws of the State of California and applicable federal securities laws.
      `
    },
    marketDataAgreement: {
      title: 'Market Data Subscriber Agreement',
      required: true,
      content: `
MARKET DATA SUBSCRIBER AGREEMENT

This Agreement governs your access to and use of real-time and delayed market data provided through Alpaca's trading platform.

1. DATA USAGE RIGHTS
Market data is provided for your personal, non-commercial use only. You may not redistribute, republish, or retransmit market data without written permission from the applicable exchanges.

2. EXCHANGE AGREEMENTS
By accepting this Agreement, you agree to comply with the terms and conditions of each exchange providing market data, including but not limited to:
- NYSE/ARCA Subscriber Agreement
- NASDAQ Subscriber Agreement
- CBOE Subscriber Agreement

3. NON-PROFESSIONAL STATUS
You represent that you qualify as a "Non-Professional" subscriber as defined by the exchanges. Professional subscribers may be subject to additional fees.

4. DATA ACCURACY
While we strive to provide accurate market data, neither Alpaca nor the exchanges guarantee the accuracy, completeness, or timeliness of market data.

5. FEES
You agree to pay all applicable market data fees as determined by the exchanges and passed through by Alpaca.

6. TERMINATION
This Agreement may be terminated by either party with 30 days' written notice. Upon termination, your access to market data will cease.
      `
    },
    privacyPolicy: {
      title: 'Privacy Policy',
      required: true,
      content: `
PRIVACY POLICY

Effective Date: ${new Date().toLocaleDateString()}

1. INFORMATION WE COLLECT
We collect information you provide directly to us, including:
- Personal information (name, address, SSN, date of birth)
- Financial information (income, net worth, investment experience)
- Trading activity and account history
- Device and usage information

2. HOW WE USE YOUR INFORMATION
We use your information to:
- Open and maintain your brokerage account
- Execute your trading instructions
- Comply with legal and regulatory requirements
- Detect and prevent fraud
- Improve our services

3. INFORMATION SHARING
We may share your information with:
- Regulatory authorities as required by law
- Our clearing firm for trade execution and settlement
- Service providers who assist in our operations
- Other parties with your consent

4. DATA SECURITY
We implement administrative, technical, and physical safeguards designed to protect your information. However, no security system is impenetrable.

5. YOUR RIGHTS
You have the right to:
- Access your personal information
- Request corrections to your information
- Opt out of marketing communications
- Request deletion of your account

6. CONTACT US
If you have questions about this Privacy Policy, please contact us at privacy@alpaca.markets.
      `
    },
    communicationConsent: {
      title: 'Electronic Communication Consent',
      required: false,
      content: `
CONSENT TO ELECTRONIC DELIVERY OF COMMUNICATIONS

By providing your consent, you agree to receive all account communications electronically.

1. SCOPE OF CONSENT
This consent applies to all account statements, trade confirmations, tax documents, proxy materials, and other communications related to your account.

2. SYSTEM REQUIREMENTS
To receive electronic communications, you must have:
- A valid email address
- Internet access
- PDF reader software
- A printer or storage device for retaining documents

3. WITHDRAWING CONSENT
You may withdraw your consent at any time by contacting customer support. Paper delivery fees may apply.

4. UPDATING YOUR EMAIL
You must keep your email address current. Failure to maintain a valid email address may result in important communications being missed.
      `
    },
    w9Certification: {
      title: 'Form W-9 Certification',
      required: true,
      content: `
FORM W-9 SUBSTITUTE - TAXPAYER IDENTIFICATION NUMBER CERTIFICATION

Under penalties of perjury, I certify that:

1. The taxpayer identification number (TIN) provided in my account application is correct.

2. I am not subject to backup withholding because:
   (a) I am exempt from backup withholding, or
   (b) I have not been notified by the IRS that I am subject to backup withholding, or
   (c) The IRS has notified me that I am no longer subject to backup withholding.

3. I am a U.S. citizen or other U.S. person (including a U.S. resident alien).

4. The FATCA code(s) entered on this form (if any) indicating that I am exempt from FATCA reporting is correct.

CERTIFICATION INSTRUCTIONS
You must cross out item 2 above if you have been notified by the IRS that you are currently subject to backup withholding because you have failed to report all interest and dividends on your tax return.

The Internal Revenue Service does not require your consent to any provision of this document other than the certifications required to avoid backup withholding.
      `
    }
  };
  
  return (
    <div className="screen-content">
      <div className="screen-header">
        <h2>Account Agreements</h2>
        <p>Please review and accept the following agreements to open your trading account. Click each agreement to read the full text.</p>
      </div>
      
      <div className="agreements-container">
        {Object.entries(agreementContent).map(([key, agreement]) => (
          <div key={key} className="agreement-section">
            <div className="agreement-header">
              <div className="agreement-title-row">
                <div className="checkbox-wrapper">
                  <input
                    type="checkbox"
                    id={key}
                    checked={agreements[key as keyof AgreementsData]}
                    onChange={() => handleCheckboxChange(key as keyof AgreementsData)}
                    className={errors[key] ? 'error' : ''}
                  />
                  <label htmlFor={key}>
                    <span className="agreement-title">
                      {agreement.title}
                      {agreement.required && <span className="required-indicator"> *</span>}
                    </span>
                  </label>
                </div>
                <button
                  type="button"
                  className="expand-button"
                  onClick={() => toggleExpanded(key)}
                  aria-label={expandedAgreements.has(key) ? 'Collapse' : 'Expand'}
                >
                  {expandedAgreements.has(key) ? (
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                      <path d="M18 15L12 9L6 15" stroke="currentColor" strokeWidth="2" strokeLinecap="round"/>
                    </svg>
                  ) : (
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                      <path d="M6 9L12 15L18 9" stroke="currentColor" strokeWidth="2" strokeLinecap="round"/>
                    </svg>
                  )}
                </button>
              </div>
              {errors[key] && <span className="error-message">{errors[key]}</span>}
            </div>
            
            {expandedAgreements.has(key) && (
              <div className="agreement-content">
                <pre>{agreement.content.trim()}</pre>
              </div>
            )}
          </div>
        ))}
      </div>
      
      <div className="info-box">
        <h4>
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" style={{ display: 'inline-block', verticalAlign: 'middle', marginRight: '8px' }}>
            <path d="M12 9V13M12 17H12.01M21 12C21 16.9706 16.9706 21 12 21C7.02944 21 3 16.9706 3 12C3 7.02944 7.02944 3 12 3C16.9706 3 21 7.02944 21 12Z" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round"/>
          </svg>
          Important Information
        </h4>
        <ul>
          <li>Required agreements are marked with an asterisk (*)</li>
          <li>Electronic communication consent is optional but recommended to avoid paper fees</li>
          <li>Please read each agreement carefully before accepting</li>
          <li>Your acceptance will be recorded with a timestamp</li>
        </ul>
      </div>
      
      <style>{`
        .agreements-container {
          margin: 24px 0;
        }
        
        .agreement-section {
          margin-bottom: 16px;
          border: 1px solid #2a2a2a;
          border-radius: 8px;
          overflow: hidden;
          background-color: #1a1a1a;
        }
        
        .agreement-header {
          padding: 16px;
        }
        
        .agreement-title-row {
          display: flex;
          justify-content: space-between;
          align-items: center;
        }
        
        .checkbox-wrapper {
          display: flex;
          align-items: center;
          flex: 1;
        }
        
        .checkbox-wrapper input[type="checkbox"] {
          width: 20px;
          height: 20px;
          margin-right: 12px;
          cursor: pointer;
        }
        
        .checkbox-wrapper label {
          cursor: pointer;
          margin: 0;
          flex: 1;
        }
        
        .agreement-title {
          font-size: 16px;
          color: #e5e5e5;
          font-weight: 500;
        }
        
        .required-indicator {
          color: #ef4444;
        }
        
        .expand-button {
          background: none;
          border: none;
          color: #9ca3af;
          cursor: pointer;
          padding: 4px;
          display: flex;
          align-items: center;
          justify-content: center;
          transition: color 0.2s;
        }
        
        .expand-button:hover {
          color: #e5e5e5;
        }
        
        .agreement-content {
          padding: 0 16px 16px;
          max-height: 300px;
          overflow-y: auto;
        }
        
        .agreement-content pre {
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
          font-size: 13px;
          line-height: 1.6;
          color: #e5e5e5;
          white-space: pre-wrap;
          margin: 0;
        }
        
        .error-message {
          color: #ef4444;
          font-size: 12px;
          margin-top: 4px;
          display: block;
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
        
        .info-box ul {
          margin: 0;
          padding-left: 24px;
          color: #9ca3af;
          font-size: 14px;
        }
        
        .info-box li {
          margin: 4px 0;
        }
        
        /* Custom scrollbar for agreement content */
        .agreement-content::-webkit-scrollbar {
          width: 6px;
        }
        
        .agreement-content::-webkit-scrollbar-track {
          background: #0a0a0a;
          border-radius: 3px;
        }
        
        .agreement-content::-webkit-scrollbar-thumb {
          background: #4a4a4a;
          border-radius: 3px;
        }
        
        .agreement-content::-webkit-scrollbar-thumb:hover {
          background: #5a5a5a;
        }
        
        @media (max-width: 768px) {
          .agreement-title {
            font-size: 14px;
          }
          
          .agreement-content pre {
            font-size: 12px;
          }
        }
      `}</style>
      
      <div className="screen-actions">
        <button 
          className="btn-primary" 
          onClick={handleSubmit}
        >
          I Agree to the Terms Above
        </button>
      </div>
    </div>
  );
};

export default AgreementsScreen;