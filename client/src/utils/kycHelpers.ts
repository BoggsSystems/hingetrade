export interface KYCProgress {
  currentStep: string;
  completedSteps: string[];
  progress: Record<string, any>;
  lastUpdated?: string | null;
}

const KYC_STEPS = [
  'welcome',
  'accountCredentials',
  'personalInfo',
  'address',
  'identity',
  'documents',
  'financialProfile',
  'agreements',
  'bankAccount',
  'review'
];

export const calculateKYCCompletionPercentage = (progress: KYCProgress): number => {
  // Welcome and review steps don't count towards completion
  const countableSteps = KYC_STEPS.filter(step => step !== 'welcome' && step !== 'review');
  const totalSteps = countableSteps.length;
  
  // Count completed steps (excluding welcome and review)
  const completedCount = progress.completedSteps.filter(
    step => countableSteps.includes(step)
  ).length;
  
  return Math.round((completedCount / totalSteps) * 100);
};

export const getEstimatedTimeRemaining = (completionPercentage: number): number => {
  // Estimate ~1.5 minutes per step on average
  const avgMinutesPerStep = 1.5;
  const totalSteps = KYC_STEPS.filter(step => step !== 'welcome' && step !== 'review').length;
  const remainingSteps = Math.ceil((totalSteps * (100 - completionPercentage)) / 100);
  
  return Math.ceil(remainingSteps * avgMinutesPerStep);
};

export const getStepDisplayName = (stepKey: string): string => {
  const displayNames: Record<string, string> = {
    welcome: 'Welcome',
    accountCredentials: 'Account Setup',
    personalInfo: 'Personal Information',
    address: 'Address',
    identity: 'Identity Verification',
    documents: 'Document Upload',
    financialProfile: 'Financial Profile',
    agreements: 'Agreements',
    bankAccount: 'Bank Account',
    review: 'Review & Submit'
  };
  
  return displayNames[stepKey] || stepKey;
};

export const isStepComplete = (stepKey: string, progress: KYCProgress): boolean => {
  return progress.completedSteps.includes(stepKey);
};

export const getNextIncompleteStep = (progress: KYCProgress): string => {
  for (const step of KYC_STEPS) {
    if (step !== 'welcome' && !isStepComplete(step, progress)) {
      return step;
    }
  }
  return 'review';
};