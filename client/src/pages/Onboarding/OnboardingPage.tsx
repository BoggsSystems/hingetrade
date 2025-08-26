import React, { useState, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import { debugLogger } from '../../utils/debugLogger';
import { kycService } from '../../services/kycService';
import { SwitchTransition, CSSTransition } from 'react-transition-group';

// Import all screens
import WelcomeScreen from '../../components/Onboarding/screens/WelcomeScreen';
import AccountCredentialsScreen from '../../components/Onboarding/screens/AccountCredentialsScreen';
import type { AccountCredentialsData } from '../../components/Onboarding/screens/AccountCredentialsScreen';
import PersonalInfoScreen from '../../components/Onboarding/screens/PersonalInfoScreen';
import AddressScreen from '../../components/Onboarding/screens/AddressScreen';
import IdentityVerificationScreen from '../../components/Onboarding/screens/IdentityVerificationScreen';
import DocumentUploadScreen from '../../components/Onboarding/screens/DocumentUploadScreen';
import FinancialProfileScreen from '../../components/Onboarding/screens/FinancialProfileScreen';
import AgreementsScreen from '../../components/Onboarding/screens/AgreementsScreen';
import BankAccountScreen from '../../components/Onboarding/screens/BankAccountScreen';
import ReviewSubmitScreen from '../../components/Onboarding/screens/ReviewSubmitScreen';
import SubmissionSuccessScreen from '../../components/Onboarding/screens/SubmissionSuccessScreen';
import SubmissionErrorScreen from '../../components/Onboarding/screens/SubmissionErrorScreen';

// Import styles
import '../../components/Onboarding/OnboardingModal.css';
import '../../components/Onboarding/OnboardingModalTransitions.css';
import './OnboardingPage.css';

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
  };
  documents?: {
    idType: 'drivers_license' | 'passport';
    idFront: File | null;
    idBack?: File | null;
    idFrontPreview?: string;
    idBackPreview?: string;
  };
  financialProfile?: {
    annualIncome: string;
    netWorth: string;
    liquidNetWorth: string;
    fundingSource: string;
    investmentObjective: string;
    investmentExperience: string;
    riskTolerance: string;
  };
  agreements?: {
    customerAgreement: boolean;
    marketDataAgreement: boolean;
    privacyPolicy: boolean;
    communicationConsent: boolean;
    w9Certification: boolean;
  };
  bankAccount?: {
    accountType: string;
    routingNumber: string;
    accountNumber: string;
    bankName: string;
  };
}

const OnboardingPage: React.FC = () => {
  const navigate = useNavigate();
  const { register } = useAuth();
  const [currentStep, setCurrentStep] = useState(0);
  const [kycData, setKycData] = useState<KYCData>({});
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submissionError, setSubmissionError] = useState<string | null>(null);
  const [submissionSuccess, setSubmissionSuccess] = useState(false);
  const nodeRef = useRef<HTMLDivElement>(null);
  
  const handleClose = () => {
    debugLogger.info('User exiting onboarding process');
    navigate('/');
  };
  
  const handleComplete = async () => {
    try {
      setIsSubmitting(true);
      setSubmissionError(null);
      debugLogger.info('Completing onboarding process', { kycData });
      
      // First register the user
      const credentials = kycData.accountCredentials!;
      
      debugLogger.info('Registering user...');
      const newUser = await register(
        credentials.email, 
        credentials.password, 
        credentials.username
      );
      debugLogger.info('Registration successful', { userId: newUser.id });
      
      // Then submit KYC data
      const kycResponse = await kycService.submitKyc(kycData);
      debugLogger.info('KYC submission response:', kycResponse);
      
      if (kycResponse.success) {
        debugLogger.info('KYC submitted successfully');
        setSubmissionSuccess(true);
        setCurrentStep(steps.length); // Move to success screen
      } else {
        throw new Error(kycResponse.message || 'KYC submission failed');
      }
    } catch (error: any) {
      debugLogger.error('Onboarding completion error:', error);
      setSubmissionError(error.message || 'Failed to complete onboarding');
      setCurrentStep(steps.length + 1); // Move to error screen
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleStepComplete = (stepName: string, data: any) => {
    setKycData(prev => ({ ...prev, [stepName]: data }));
    
    if (currentStep < steps.length - 1) {
      setCurrentStep(currentStep + 1);
    } else {
      handleComplete();
    }
  };
  
  const steps = [
    <WelcomeScreen onNext={() => setCurrentStep(currentStep + 1)} />,
    <AccountCredentialsScreen 
      onNext={(data) => handleStepComplete('accountCredentials', data)} 
      data={kycData.accountCredentials}
    />,
    <PersonalInfoScreen 
      onNext={(data) => handleStepComplete('personalInfo', data)} 
      data={kycData.personalInfo}
    />,
    <AddressScreen 
      onNext={(data) => handleStepComplete('address', data)} 
      data={kycData.address}
    />,
    <IdentityVerificationScreen 
      onNext={(data) => handleStepComplete('identity', data)} 
      data={kycData.identity}
    />,
    <DocumentUploadScreen 
      onNext={(data) => handleStepComplete('documents', data)} 
      data={kycData.documents}
    />,
    <FinancialProfileScreen 
      onNext={(data) => handleStepComplete('financialProfile', data)} 
      data={kycData.financialProfile}
    />,
    <AgreementsScreen 
      onNext={(data) => handleStepComplete('agreements', data)} 
      data={kycData.agreements}
    />,
    <BankAccountScreen 
      onNext={(data) => handleStepComplete('bankAccount', data)} 
      data={kycData.bankAccount}
    />,
    <ReviewSubmitScreen 
      onSubmit={() => handleComplete()}
      kycData={kycData as any}
      onEdit={(step) => {
        if (step >= 0) setCurrentStep(step);
      }}
      isSubmitting={isSubmitting}
    />
  ];
  
  // Add success and error screens dynamically based on state
  const getCurrentScreen = () => {
    if (submissionSuccess && currentStep === steps.length) {
      return (
        <SubmissionSuccessScreen 
          onContinue={() => navigate('/dashboard')} 
        />
      );
    }
    
    if (submissionError && currentStep === steps.length + 1) {
      return (
        <SubmissionErrorScreen 
          error={submissionError}
          onRetry={() => {
            setSubmissionError(null);
            setCurrentStep(steps.length - 1); // Go back to review screen
          }}
          onClose={handleClose}
        />
      );
    }
    
    return steps[currentStep];
  };
  
  const canGoBack = currentStep > 0 && !submissionSuccess && !submissionError;
  const isLastStep = currentStep === steps.length - 1;
  const showProgress = !submissionSuccess && !submissionError;

  return (
    <div className="onboarding-page">
      <div className="onboarding-background" />
      <div className="onboarding-container">
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
        
        {showProgress && (
          <div className="onboarding-progress">
            {steps.map((_, index) => (
              <div 
                key={index} 
                className={`progress-dot ${currentStep >= index ? 'active' : ''} ${currentStep === index ? 'current' : ''}`}
                title={`Step ${index + 1}`}
              />
            ))}
          </div>
        )}
        
        <div className="onboarding-screen-wrapper">
          <SwitchTransition mode="out-in">
            <CSSTransition
              key={currentStep}
              nodeRef={nodeRef}
              timeout={300}
              classNames="slide"
            >
              <div ref={nodeRef} className="onboarding-screen">
                {getCurrentScreen()}
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

export default OnboardingPage;