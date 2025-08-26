import React, { useState, useEffect, useRef } from 'react';
import { SwitchTransition, CSSTransition } from 'react-transition-group';
import WelcomeScreen from './screens/WelcomeScreen';
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
  onComplete: (data: any) => void;
}

export interface KYCData {
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
  
  // Reset to first step whenever the modal is opened
  useEffect(() => {
    if (isOpen) {
      setCurrentStep(0);
      setKYCData({});
    }
  }, [isOpen]);
  
  if (!isOpen) return null;
  
  const updateKYCData = (section: keyof KYCData, data: any) => {
    setKYCData(prev => ({
      ...prev,
      [section]: data
    }));
  };
  
  const steps = [
    <WelcomeScreen 
      onNext={() => setCurrentStep(1)} 
    />,
    <PersonalInfoScreen 
      onNext={(data) => {
        updateKYCData('personalInfo', data);
        setCurrentStep(2);
      }}
      data={kycData.personalInfo}
    />,
    <AddressScreen 
      onNext={(data) => {
        updateKYCData('address', data);
        setCurrentStep(3);
      }}
      data={kycData.address}
    />,
    <IdentityVerificationScreen 
      onNext={(data) => {
        updateKYCData('identity', data);
        setCurrentStep(4);
      }}
      data={kycData.identity}
    />,
    <DocumentUploadScreen 
      onNext={(data) => {
        updateKYCData('documents', data);
        setCurrentStep(5);
      }}
      data={kycData.documents}
    />,
    <FinancialProfileScreen 
      onNext={(data) => {
        updateKYCData('financialProfile', data);
        setCurrentStep(6);
      }}
      data={kycData.financialProfile}
    />,
    <AgreementsScreen 
      onNext={(data) => {
        updateKYCData('agreements', data);
        setCurrentStep(7);
      }}
      data={kycData.agreements}
    />,
    <BankAccountScreen 
      onNext={(data) => {
        updateKYCData('bankAccount', data);
        setCurrentStep(8);
      }}
      data={kycData.bankAccount}
    />,
    <ReviewSubmitScreen 
      kycData={kycData}
      onSubmit={() => onComplete(kycData)}
      onEdit={(step) => setCurrentStep(step)}
    />
  ];
  
  const handleOverlayClick = (event: React.MouseEvent<HTMLDivElement>) => {
    // Prevent closing during KYC process
    event.preventDefault();
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
            onClick={onClose}
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
            {!isLastStep && (
              <button 
                className="btn-text" 
                onClick={onClose}
              >
                Save & Exit
              </button>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default KYCOnboardingModal;