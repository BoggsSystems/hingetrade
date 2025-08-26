import React, { useState, useEffect, useRef } from 'react';
import { useAuth } from '../../contexts/AuthContext';
import { kycService } from '../../services/kycService';
import { SwitchTransition, CSSTransition } from 'react-transition-group';
import WelcomeScreen from './screens/WelcomeScreen';
import WelcomeBackScreen from './screens/WelcomeBackScreen';
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
import { calculateKYCCompletionPercentage, getNextIncompleteStep } from '../../utils/kycHelpers';
import './OnboardingModal.css';
import './OnboardingModalTransitions.css';

interface KYCOnboardingModalProps {
  isOpen: boolean;
  onClose: () => void;
  onComplete: (data: any) => void;
  onRegister?: (email: string, password: string, username: string) => Promise<any>;
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
  onComplete,
  onRegister 
}) => {
  const { user, logout } = useAuth();
  const [currentStep, setCurrentStep] = useState(0);
  const [kycData, setKYCData] = useState<KYCData>({});
  const [isLoadingProgress, setIsLoadingProgress] = useState(false);
  const [isResuming, setIsResuming] = useState(false);
  const [savedProgress, setSavedProgress] = useState<any>(null);
  const nodeRef = useRef<HTMLDivElement>(null);
  
  // Load saved progress when modal opens
  useEffect(() => {
    if (isOpen) {
      // Only load progress if:
      // 1. User is authenticated (has a user object)
      // 2. We're not in fresh registration mode (onRegister is undefined)
      // This prevents unnecessary API calls from the landing page
      if (user && onRegister === undefined) {
        loadSavedProgress();
      } else if (onRegister) {
        // Fresh registration - start from the beginning
        setCurrentStep(0);
        setKYCData({});
        setIsLoadingProgress(false);
      }
    }
  }, [isOpen, user, onRegister]);
  
  const loadSavedProgress = async () => {
    // Double-check we have a user before making API call
    if (!user) {
      setIsLoadingProgress(false);
      return;
    }
    
    try {
      setIsLoadingProgress(true);
      const progress = await kycService.getProgress();
      setSavedProgress(progress);
      
      if (progress.progress && Object.keys(progress.progress).length > 0) {
        // Restore saved data
        const restoredData: KYCData = {};
        
        if (progress.progress.personalInfo) {
          restoredData.personalInfo = progress.progress.personalInfo;
        }
        if (progress.progress.address) {
          restoredData.address = progress.progress.address;
        }
        if (progress.progress.identity) {
          restoredData.identity = progress.progress.identity;
        }
        if (progress.progress.documents) {
          restoredData.documents = progress.progress.documents;
        }
        if (progress.progress.financialProfile) {
          restoredData.financialProfile = progress.progress.financialProfile;
        }
        if (progress.progress.agreements) {
          restoredData.agreements = progress.progress.agreements;
        }
        if (progress.progress.bankAccount) {
          restoredData.bankAccount = progress.progress.bankAccount;
        }
        
        setKYCData(restoredData);
        
        // Set current step based on progress
        const stepMap: Record<string, number> = {
          'welcome': 0,
          'accountCredentials': 1,
          'personalInfo': 2,
          'address': 3,
          'identity': 4,
          'documents': 5,
          'financialProfile': 6,
          'agreements': 7,
          'bankAccount': 8,
          'review': 9
        };
        
        const savedStep = stepMap[progress.currentStep] || 0;
        // If user has already registered and has progress, show welcome back
        if (onRegister === undefined && progress.completedSteps.length > 0) {
          setIsResuming(true);
          setCurrentStep(0); // Show welcome back screen
        } else {
          setCurrentStep(savedStep > 1 ? savedStep : 2);
        }
      } else {
        // No saved progress, start fresh
        setCurrentStep(onRegister ? 0 : 2);
        setKYCData({});
      }
    } catch (error) {
      console.error('Failed to load KYC progress:', error);
      setCurrentStep(onRegister ? 0 : 2);
      setKYCData({});
    } finally {
      setIsLoadingProgress(false);
    }
  };
  
  if (!isOpen) return null;
  
  const updateKYCData = async (section: keyof KYCData, data: any) => {
    setKYCData(prev => ({
      ...prev,
      [section]: data
    }));
    
    // Save progress to backend
    try {
      const stepName = kycService.mapStepName(section);
      await kycService.updateProgress(stepName, data);
    } catch (error) {
      console.error('Failed to save progress:', error);
      // Continue anyway - don't block the user
    }
  };
  
  const handleAccountCredentials = async (data: AccountCredentialsData) => {
    updateKYCData('accountCredentials', data);
    
    // If onRegister is provided, attempt registration
    if (onRegister) {
      try {
        const user = await onRegister(data.email, data.password, data.username);
        // Store the registered user data if needed
        console.log('Registration successful:', user);
        setCurrentStep(2);
      } catch (error) {
        console.error('Registration failed:', error);
        // Handle error - show message, allow retry, etc.
        throw error; // Re-throw to be handled by the screen
      }
    } else {
      setCurrentStep(2);
    }
  };
  
  const handleContinueFromWelcomeBack = () => {
    if (savedProgress) {
      const nextStep = getNextIncompleteStep(savedProgress);
      const stepMap: Record<string, number> = {
        'accountCredentials': 1,
        'personalInfo': 2,
        'address': 3,
        'identity': 4,
        'documents': 5,
        'financialProfile': 6,
        'agreements': 7,
        'bankAccount': 8,
        'review': 9
      };
      setCurrentStep(stepMap[nextStep] || 2);
    }
  };

  const handleStartOver = async () => {
    if (confirm('Are you sure you want to start over? This will clear all your saved progress.')) {
      try {
        // TODO: Call reset endpoint when implemented
        // await kycService.reset();
        setKYCData({});
        setCurrentStep(2); // Skip to personal info since user is already registered
        setIsResuming(false);
      } catch (error) {
        console.error('Failed to reset KYC:', error);
      }
    }
  };

  const steps = [
    isResuming ? (
      <WelcomeBackScreen
        onContinue={handleContinueFromWelcomeBack}
        onStartOver={handleStartOver}
        progress={savedProgress}
        completionPercentage={savedProgress ? calculateKYCCompletionPercentage(savedProgress) : 0}
        username={user?.username}
      />
    ) : (
      <WelcomeScreen 
        onNext={() => setCurrentStep(1)} 
      />
    ),
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
      onSubmit={async () => {
        try {
          // Submit KYC to backend
          await kycService.submitKyc(kycData);
          // Call the completion handler
          onComplete(kycData);
        } catch (error) {
          console.error('Failed to submit KYC:', error);
          throw error;
        }
      }}
      onEdit={(step) => setCurrentStep(step)}
    />
  ];
  
  const handleOverlayClick = (event: React.MouseEvent<HTMLDivElement>) => {
    // Prevent closing during KYC process
    event.preventDefault();
  };

  const handleClose = async () => {
    // Clear authentication data and redirect to landing page
    try {
      await logout();
      onClose();
    } catch (error) {
      console.error('Error during logout:', error);
      // Still close the modal even if logout fails
      onClose();
    }
  };
  
  const canGoBack = currentStep > 0;
  const isLastStep = currentStep === steps.length - 1;
  const canSaveAndExit = !isLastStep && (currentStep > 1 || (isResuming && currentStep === 0));
  
  if (isLoadingProgress) {
    return (
      <div className="onboarding-overlay">
        <div className="onboarding-modal kyc-modal" style={{ display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <div style={{ textAlign: 'center' }}>
            <div className="spinner" style={{ marginBottom: '16px' }}></div>
            <p>Loading your progress...</p>
          </div>
        </div>
      </div>
    );
  }

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
            {canSaveAndExit && (
              <button 
                className="btn-text" 
                onClick={handleClose}
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