import React, { useState, useEffect } from 'react';

interface BankAccountScreenProps {
  onNext: (data: BankAccountData) => void;
  data?: BankAccountData;
}

export interface BankAccountData {
  accountType: string;
  routingNumber: string;
  accountNumber: string;
  bankName: string;
}

interface PlaidAccount {
  id: string;
  name: string;
  mask: string;
  type: string;
  subtype: string;
  bankName: string;
}

const BankAccountScreen: React.FC<BankAccountScreenProps> = ({ onNext, data }) => {
  const [linkMethod, setLinkMethod] = useState<'plaid' | 'manual'>('plaid');
  const [linkedAccount, setLinkedAccount] = useState<PlaidAccount | null>(null);
  const [isPlaidLoading, setIsPlaidLoading] = useState(false);
  const [showManualForm] = useState(false);
  const [verificationStatus, setVerificationStatus] = useState<'pending' | 'verified' | null>(null);
  
  // Manual form data
  const [formData, setFormData] = useState<BankAccountData>({
    accountType: data?.accountType || 'checking',
    routingNumber: data?.routingNumber || '',
    accountNumber: data?.accountNumber || '',
    bankName: data?.bankName || ''
  });
  
  const [errors, setErrors] = useState<Record<string, string>>({});
  
  // Simulate Plaid Link initialization
  useEffect(() => {
    // In production, this would initialize the Plaid Link SDK
    // window.Plaid.create({ token, onSuccess, onExit })
  }, []);
  
  const handlePlaidLink = () => {
    setIsPlaidLoading(true);
    
    // Simulate Plaid Link flow
    setTimeout(() => {
      // Simulate successful bank connection
      const mockAccount: PlaidAccount = {
        id: 'plaid_' + Date.now(),
        name: 'Chase Total Checking',
        mask: '4567',
        type: 'depository',
        subtype: 'checking',
        bankName: 'Chase Bank'
      };
      
      setLinkedAccount(mockAccount);
      setIsPlaidLoading(false);
      setVerificationStatus('verified');
      
      // In production, this would exchange public token for access token
      // and send account details to backend
    }, 2000);
  };
  
  const handleManualSubmit = () => {
    if (validateManualForm()) {
      // In production, this would trigger micro-deposit verification
      setVerificationStatus('pending');
    }
  };
  
  const validateManualForm = (): boolean => {
    const newErrors: Record<string, string> = {};
    
    // Routing number validation (9 digits)
    if (!formData.routingNumber) {
      newErrors.routingNumber = 'Routing number is required';
    } else if (!/^\d{9}$/.test(formData.routingNumber)) {
      newErrors.routingNumber = 'Routing number must be 9 digits';
    }
    
    // Account number validation
    if (!formData.accountNumber) {
      newErrors.accountNumber = 'Account number is required';
    } else if (!/^\d{4,17}$/.test(formData.accountNumber)) {
      newErrors.accountNumber = 'Invalid account number';
    }
    
    // Bank name validation
    if (!formData.bankName.trim()) {
      newErrors.bankName = 'Bank name is required';
    }
    
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };
  
  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    const { name, value } = e.target;
    
    // For routing number, auto-lookup bank name (in production)
    if (name === 'routingNumber' && value.length === 9) {
      // Simulate bank name lookup
      const bankLookup: Record<string, string> = {
        '121000248': 'Wells Fargo',
        '322271627': 'Chase Bank',
        '021000021': 'JPMorgan Chase',
        '011401533': 'Bank of America'
      };
      
      const bankName = bankLookup[value] || '';
      setFormData(prev => ({ ...prev, bankName }));
    }
    
    setFormData(prev => ({ ...prev, [name]: value }));
    
    // Clear error
    if (errors[name]) {
      setErrors(prev => ({ ...prev, [name]: '' }));
    }
  };
  
  const handleNext = () => {
    if (linkedAccount) {
      // Convert Plaid account to our format
      onNext({
        accountType: linkedAccount.subtype,
        routingNumber: '****', // Would come from Plaid in production
        accountNumber: `****${linkedAccount.mask}`,
        bankName: linkedAccount.bankName
      });
    } else if (verificationStatus === 'pending') {
      onNext(formData);
    }
  };
  
  const canContinue = linkedAccount !== null || verificationStatus === 'pending';
  
  return (
    <div className="screen-content">
      <div className="screen-header">
        <h2>Bank Account</h2>
        <p>Link your bank account to fund your trading account. We use bank-level encryption to keep your information secure.</p>
      </div>
      
      {!linkedAccount && !verificationStatus && (
        <div className="link-method-selector">
          <div className="method-cards">
            <div 
              className={`method-card ${linkMethod === 'plaid' ? 'selected' : ''}`}
              onClick={() => setLinkMethod('plaid')}
            >
              <div className="method-header">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                  <path d="M12 2L2 7L12 12L22 7L12 2Z" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
                  <path d="M2 17L12 22L22 17" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
                  <path d="M2 12L12 17L22 12" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
                </svg>
                <h3>Instant Verification</h3>
                <span className="recommended">Recommended</span>
              </div>
              <p>Securely connect your bank account for instant verification using Plaid</p>
            </div>
            
            <div 
              className={`method-card ${linkMethod === 'manual' ? 'selected' : ''}`}
              onClick={() => setLinkMethod('manual')}
            >
              <div className="method-header">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                  <path d="M14 2H6C4.9 2 4 2.9 4 4V20C4 21.1 4.9 22 6 22H18C19.1 22 20 21.1 20 20V8L14 2Z" stroke="currentColor" strokeWidth="1.5"/>
                  <path d="M14 2V8H20" stroke="currentColor" strokeWidth="1.5"/>
                  <path d="M16 13H8" stroke="currentColor" strokeWidth="1.5"/>
                  <path d="M16 17H8" stroke="currentColor" strokeWidth="1.5"/>
                  <path d="M10 9H9H8" stroke="currentColor" strokeWidth="1.5"/>
                </svg>
                <h3>Manual Entry</h3>
              </div>
              <p>Enter your routing and account numbers manually (2-3 days for verification)</p>
            </div>
          </div>
          
          {linkMethod === 'plaid' && !showManualForm && (
            <div className="plaid-section">
              <button 
                className="btn-primary btn-plaid" 
                onClick={handlePlaidLink}
                disabled={isPlaidLoading}
              >
                {isPlaidLoading ? (
                  <>
                    <span className="spinner"></span>
                    Connecting...
                  </>
                ) : (
                  <>
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                      <path d="M13 11L22 2M22 2H16M22 2V8" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                      <path d="M22 12V19C22 20.1 21.1 21 20 21H4C2.9 21 2 20.1 2 19V5C2 3.9 2.9 3 4 3H12" stroke="currentColor" strokeWidth="2" strokeLinecap="round"/>
                    </svg>
                    Connect Bank Account
                  </>
                )}
              </button>
              
              <div className="security-info">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                  <path d="M12 2L3.5 7V12C3.5 16.5 6.5 20.74 12 22C17.5 20.74 20.5 16.5 20.5 12V7L12 2Z" stroke="currentColor" strokeWidth="1.5"/>
                  <path d="M9 12L11 14L15 10" stroke="currentColor" strokeWidth="1.5"/>
                </svg>
                <span>Your login credentials are never shared with us</span>
              </div>
            </div>
          )}
          
          {(linkMethod === 'manual' || showManualForm) && (
            <div className="manual-form">
              <div className="form-group">
                <label htmlFor="accountType">Account Type</label>
                <select
                  id="accountType"
                  name="accountType"
                  value={formData.accountType}
                  onChange={handleChange}
                >
                  <option value="checking">Checking</option>
                  <option value="savings">Savings</option>
                </select>
              </div>
              
              <div className="form-group">
                <label htmlFor="routingNumber">Routing Number</label>
                <input
                  type="text"
                  id="routingNumber"
                  name="routingNumber"
                  value={formData.routingNumber}
                  onChange={handleChange}
                  placeholder="9 digits"
                  maxLength={9}
                  className={errors.routingNumber ? 'error' : ''}
                />
                {errors.routingNumber && <span className="error-message">{errors.routingNumber}</span>}
                <div className="help-text">The 9-digit number on the bottom left of your check</div>
              </div>
              
              <div className="form-group">
                <label htmlFor="accountNumber">Account Number</label>
                <input
                  type="text"
                  id="accountNumber"
                  name="accountNumber"
                  value={formData.accountNumber}
                  onChange={handleChange}
                  placeholder="Your account number"
                  className={errors.accountNumber ? 'error' : ''}
                />
                {errors.accountNumber && <span className="error-message">{errors.accountNumber}</span>}
                <div className="help-text">The number next to the routing number on your check</div>
              </div>
              
              <div className="form-group">
                <label htmlFor="bankName">Bank Name</label>
                <input
                  type="text"
                  id="bankName"
                  name="bankName"
                  value={formData.bankName}
                  onChange={handleChange}
                  placeholder="e.g., Chase Bank"
                  className={errors.bankName ? 'error' : ''}
                />
                {errors.bankName && <span className="error-message">{errors.bankName}</span>}
              </div>
              
              <button 
                className="btn-primary" 
                onClick={handleManualSubmit}
                style={{ marginTop: '24px' }}
              >
                Verify Account
              </button>
            </div>
          )}
        </div>
      )}
      
      {linkedAccount && (
        <div className="linked-account">
          <div className="success-message">
            <svg width="48" height="48" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
              <circle cx="12" cy="12" r="10" fill="#10b981" fillOpacity="0.2" stroke="#10b981" strokeWidth="1.5"/>
              <path d="M8 12L11 15L16 9" stroke="#10b981" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
            <h3>Bank Account Connected!</h3>
          </div>
          
          <div className="account-details">
            <div className="account-card">
              <div className="bank-icon">
                <svg width="32" height="32" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                  <path d="M3 21H21" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                  <path d="M5 21V7L12 2L19 7V21" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                  <path d="M9 21V12H15V21" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                  <path d="M10 9H10.01" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                  <path d="M14 9H14.01" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                </svg>
              </div>
              <div className="account-info">
                <h4>{linkedAccount.bankName}</h4>
                <p>{linkedAccount.name}</p>
                <p className="account-number">Account ending in {linkedAccount.mask}</p>
              </div>
              <span className="verified-badge">Verified</span>
            </div>
            
            <button 
              className="btn-text" 
              onClick={() => {
                setLinkedAccount(null);
                setVerificationStatus(null);
              }}
            >
              Use Different Account
            </button>
          </div>
        </div>
      )}
      
      {verificationStatus === 'pending' && (
        <div className="verification-pending">
          <div className="pending-message">
            <svg width="48" height="48" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
              <circle cx="12" cy="12" r="10" stroke="#f59e0b" strokeWidth="1.5"/>
              <path d="M12 6V12L16 14" stroke="#f59e0b" strokeWidth="1.5" strokeLinecap="round"/>
            </svg>
            <h3>Verification Pending</h3>
            <p>We'll make two small deposits to your account within 2-3 business days.</p>
            <p>You'll need to confirm these amounts to complete verification.</p>
          </div>
          
          <div className="account-details">
            <div className="account-card">
              <div className="bank-icon">
                <svg width="32" height="32" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                  <path d="M3 21H21" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                  <path d="M5 21V7L12 2L19 7V21" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                  <path d="M9 21V12H15V21" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                  <path d="M10 9H10.01" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                  <path d="M14 9H14.01" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                </svg>
              </div>
              <div className="account-info">
                <h4>{formData.bankName}</h4>
                <p>{formData.accountType === 'checking' ? 'Checking' : 'Savings'} Account</p>
                <p className="account-number">Account ending in ****{formData.accountNumber.slice(-4)}</p>
              </div>
              <span className="pending-badge">Pending</span>
            </div>
          </div>
        </div>
      )}
      
      <style>{`
        .link-method-selector {
          margin-top: 24px;
        }
        
        .method-cards {
          display: grid;
          grid-template-columns: 1fr 1fr;
          gap: 16px;
          margin-bottom: 32px;
        }
        
        .method-card {
          border: 1px solid #2a2a2a;
          border-radius: 8px;
          padding: 20px;
          cursor: pointer;
          transition: all 0.2s;
          background-color: #1a1a1a;
        }
        
        .method-card:hover {
          border-color: #4a4a4a;
        }
        
        .method-card.selected {
          border-color: #4caf50;
          background-color: rgba(76, 175, 80, 0.1);
        }
        
        .method-header {
          display: flex;
          align-items: center;
          gap: 12px;
          margin-bottom: 12px;
        }
        
        .method-header svg {
          color: #4caf50;
        }
        
        .method-header h3 {
          margin: 0;
          font-size: 18px;
          color: #e5e5e5;
          flex: 1;
        }
        
        .recommended {
          background-color: #4caf50;
          color: white;
          padding: 2px 8px;
          border-radius: 4px;
          font-size: 12px;
          font-weight: 500;
        }
        
        .method-card p {
          margin: 0;
          color: #9ca3af;
          font-size: 14px;
        }
        
        .plaid-section {
          text-align: center;
          padding: 32px 0;
        }
        
        .btn-plaid {
          display: inline-flex;
          align-items: center;
          gap: 8px;
          padding: 12px 24px;
          font-size: 16px;
        }
        
        .spinner {
          width: 16px;
          height: 16px;
          border: 2px solid #ffffff30;
          border-top-color: white;
          border-radius: 50%;
          animation: spin 1s linear infinite;
        }
        
        @keyframes spin {
          to { transform: rotate(360deg); }
        }
        
        .security-info {
          display: flex;
          align-items: center;
          justify-content: center;
          gap: 8px;
          margin-top: 16px;
          color: #9ca3af;
          font-size: 14px;
        }
        
        .security-info svg {
          color: #10b981;
        }
        
        .manual-form {
          max-width: 400px;
          margin: 0 auto;
        }
        
        .help-text {
          font-size: 12px;
          color: #888;
          margin-top: 4px;
        }
        
        .linked-account,
        .verification-pending {
          text-align: center;
          padding: 32px 0;
        }
        
        .success-message,
        .pending-message {
          display: flex;
          flex-direction: column;
          align-items: center;
          gap: 16px;
          margin-bottom: 32px;
        }
        
        .success-message h3,
        .pending-message h3 {
          margin: 0;
          font-size: 24px;
          color: #e5e5e5;
        }
        
        .pending-message p {
          margin: 4px 0;
          color: #9ca3af;
          font-size: 14px;
        }
        
        .account-details {
          max-width: 400px;
          margin: 0 auto;
        }
        
        .account-card {
          display: flex;
          align-items: center;
          gap: 16px;
          padding: 20px;
          background-color: #1a1a1a;
          border: 1px solid #2a2a2a;
          border-radius: 8px;
          margin-bottom: 16px;
          text-align: left;
        }
        
        .bank-icon {
          display: flex;
          align-items: center;
          justify-content: center;
          width: 48px;
          height: 48px;
          background-color: rgba(76, 175, 80, 0.1);
          border-radius: 12px;
          color: #4caf50;
        }
        
        .bank-icon svg {
          width: 28px;
          height: 28px;
        }
        
        .account-info {
          flex: 1;
        }
        
        .account-info h4 {
          margin: 0 0 4px 0;
          font-size: 16px;
          color: #e5e5e5;
        }
        
        .account-info p {
          margin: 2px 0;
          color: #9ca3af;
          font-size: 14px;
        }
        
        .account-number {
          font-family: monospace;
        }
        
        .verified-badge,
        .pending-badge {
          padding: 4px 12px;
          border-radius: 20px;
          font-size: 12px;
          font-weight: 500;
        }
        
        .verified-badge {
          background-color: rgba(16, 185, 129, 0.2);
          color: #10b981;
        }
        
        .pending-badge {
          background-color: rgba(245, 158, 11, 0.2);
          color: #f59e0b;
        }
        
        .btn-text {
          color: #4caf50;
          text-decoration: underline;
          background: none;
          border: none;
          cursor: pointer;
          font-size: 14px;
        }
        
        @media (max-width: 768px) {
          .method-cards {
            grid-template-columns: 1fr;
          }
        }
      `}</style>
      
      <div className="screen-actions">
        <button 
          className="btn-primary" 
          onClick={handleNext}
          disabled={!canContinue}
        >
          Continue
        </button>
      </div>
    </div>
  );
};

export default BankAccountScreen;