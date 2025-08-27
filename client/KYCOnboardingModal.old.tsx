import React, { useState, useEffect, useRef } from 'react';
import { debugLogger } from '../../utils/debugLogger';
import { SwitchTransition, CSSTransition } from 'react-transition-group';
import WelcomeScreen from './screens/WelcomeScreen';
import AccountCredentialsScreen from './screens/AccountCredentialsScreen';
import type { AccountCredentialsData } from './screens/AccountCredentialsScreen';
import PersonalInfoScreen from './screens/PersonalInfoScreen';
import AddressScreen from './screens/AddressScreen';
import IdentityVerificationScreen from './screens/IdentityVerificationScreen';
import DocumentUploadScreen from './screens/DocumentUploadScreen';
import FinancialProfileScreen from './screens/FinancialProfileScreen';
import AgreementsScreen from './screens/AgreementsScreen';
import BankAccountScreen from './screens/BankAccountScreen';
import ReviewSubmitScreen from './screens/ReviewSubmitScreen';
import './OnboardingModal.css';
import './OnboardingModalTransitions.css';

interface KYCOnboardingModalProps {
  isOpen: boolean;
  onClose: () => void;
  onComplete: (data: KYCData) => void;
}

export interface KYCData {
  accountCredentials?: AccountCredentialsData;
  personalInfo?: {
    firstName: string;
    lastName: string;
    dateOfBirth: string;
    phoneNumber: string;
    email: string;
  };
  address?: {
    streetAddress: string;
    streetAddress2?: string;
    city: string;
    state: string;
    zipCode: string;
    country: string;
    isMailingSame: boolean;
    mailingAddress?: {
      streetAddress: string;
      streetAddress2?: string;
      city: string;
      state: string;
      zipCode: string;
      country: string;
    };
  };
  identity?: {
    ssn: string;
    citizenship: string;
    countryOfBirth: string;
    employmentStatus: string;
    employer?: string;
    jobTitle?: string;
  };
  documents?: {
    idType: 'drivers_license' | 'passport';
    idFront: File | null;
    idBack?: File | null;
  };
  financialProfile?: {
    annualIncome: string;
    netWorth: string;
    liquidNetWorth: string;
    investmentObjective: string;
    investmentExperience: string;
    riskTolerance: string;
    fundingSource: string[];
  };
  agreements?: {
    customerAgreement: boolean;
    marginAgreement: boolean;
    riskDisclosure: boolean;
    dataSharing: boolean;
    timestamp: string;
    ipAddress: string;
  };
  bankAccount?: {
    method: 'ach' | 'wire';
    achDetails?: {
      accountNumber: string;
      routingNumber: string;
      accountType: 'checking' | 'savings';
      bankName: string;
    };
  };
}

const KYCOnboardingModal: React.FC<KYCOnboardingModalProps> = ({ 
  isOpen, 
  onClose, 
  onComplete 
}) => {
  const [currentStep, setCurrentStep] = useState(0);
  const [kycData, setKYCData] = useState<KYCData>({});
  const nodeRef = useRef<HTMLDivElement>(null);
  
  // Reset form when modal opens
  useEffect(() => {
    if (isOpen) {
      debugLogger.info('KYC Modal opened - starting fresh');
      setCurrentStep(0);
      setKYCData({});
    }
  }, [isOpen]);
  
  
  if (!isOpen) return null;
  
  const updateKYCData = (section: keyof KYCData, data: any) => {
    debugLogger.info('Updating KYC data section', { section, hasData: !!data });
    setKYCData(prev => ({
      ...prev,
      [section]: data
    }));
  };
  
  const handleAccountCredentials = (data: AccountCredentialsData) => {
    debugLogger.info('Account credentials collected', { email: data.email, username: data.username });
    updateKYCData('accountCredentials', data);
    setCurrentStep(2); // Move to personal info
  };
  

  const steps = [
    <WelcomeScreen 
      onNext={() => setCurrentStep(1)} 
    />,
    <AccountCredentialsScreen
      onNext={handleAccountCredentials}
      data={kycData.accountCredentials}
    />,
    <PersonalInfoScreen 
      onNext={(data) => {
        updateKYCData('personalInfo', data);
        setCurrentStep(3);
      }}
      data={{
        ...kycData.personalInfo,
        // Pre-fill email from account credentials
        email: kycData.accountCredentials?.email || kycData.personalInfo?.email || ''
      }}
    />,
    <AddressScreen 
      onNext={(data) => {
        updateKYCData('address', data);
        setCurrentStep(4);
      }}
      data={kycData.address}
    />,
    <IdentityVerificationScreen 
      onNext={(data) => {
        updateKYCData('identity', data);
        setCurrentStep(5);
      }}
      data={kycData.identity}
    />,
    <DocumentUploadScreen 
      onNext={(data) => {
        updateKYCData('documents', data);
        setCurrentStep(6);
      }}
      data={kycData.documents}
    />,
    <FinancialProfileScreen 
      onNext={(data) => {
        updateKYCData('financialProfile', data);
        setCurrentStep(7);
      }}
      data={kycData.financialProfile}
    />,
    <AgreementsScreen 
      onNext={(data) => {
        updateKYCData('agreements', data);
        setCurrentStep(8);
      }}
      data={kycData.agreements}
    />,
    <BankAccountScreen 
      onNext={(data) => {
        updateKYCData('bankAccount', data);
        setCurrentStep(9);
      }}
      data={kycData.bankAccount}
    />,
    <ReviewSubmitScreen 
      kycData={kycData}
      onSubmit={() => {
        debugLogger.info('Final submit - completing onboarding with all data');
        onComplete(kycData);
      }}
      onEdit={(step) => setCurrentStep(step)}
    />
  ];
  
  const handleOverlayClick = (event: React.MouseEvent<HTMLDivElement>) => {
    // Prevent closing during KYC process
    event.preventDefault();
  };

  const handleClose = () => {
    debugLogger.info('KYC Modal closing - user quit onboarding');
    onClose();
  };
  
  const canGoBack = currentStep > 0;
  const isLastStep = currentStep === steps.length - 1;

  return (
    <div className="onboarding-overlay" onClick={handleOverlayClick}>
      <div className="onboarding-modal kyc-modal">
        <div className="onboarding-header">
          <h2>Open Trading Account</h2>
          <button 
            className="close-button" 
            onClick={handleClose}
            aria-label="Close"
          >
            ×
          </button>
        </div>
        
        <div className="onboarding-progress">
          {steps.map((_, index) => (
            <div 
              key={index} 
              className={`progress-dot ${currentStep >= index ? 'active' : ''} ${currentStep === index ? 'current' : ''}`}
              title={`Step ${index + 1}`}
            />
          ))}
        </div>
        
        <div className="onboarding-screen-wrapper">
          <SwitchTransition mode="out-in">
            <CSSTransition
              key={currentStep}
              nodeRef={nodeRef}
              timeout={300}
              classNames="slide"
            >
              <div ref={nodeRef} className="onboarding-screen">
                {steps[currentStep]}
              </div>
            </CSSTransition>
          </SwitchTransition>
        </div>
        
        <div className="onboarding-controls">
          {canGoBack && !isLastStep && (
            <button 
              className="btn-secondary" 
              onClick={() => setCurrentStep(currentStep - 1)}
            >
              Back
            </button>
          )}
          <div className="controls-right">
            {/* No Save & Exit - users must complete the entire flow */}
          </div>
        </div>
      </div>
    </div>
  );
};

export default KYCOnboardingModal;