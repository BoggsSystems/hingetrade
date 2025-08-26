import { api } from './api';
import type { KYCData } from '../pages/Onboarding/OnboardingPage';

export interface KycProgress {
  currentStep: string;
  completedSteps: string[];
  progress: Record<string, any>;
  lastUpdated?: string;
}

export interface KycStatus {
  kycStatus: string;
  kycSubmittedAt?: string;
  kycApprovedAt?: string;
}

class KycService {
  async getStatus(): Promise<KycStatus> {
    const response = await api.get('/kyc/status');
    return response.data;
  }

  async getProgress(): Promise<KycProgress> {
    const response = await api.get('/kyc/progress');
    return response.data;
  }

  async updateProgress(step: string, data: any): Promise<void> {
    const mappedStep = this.mapStepName(step);
    await api.post(`/kyc/progress/${mappedStep}`, { data });
  }

  async submitKyc(kycData: KYCData): Promise<{ success: boolean; message: string }> {
    try {
      // Prepare documents with base64 conversion if needed
      let documentsData: any = null;
      if (kycData.documents) {
        documentsData = {
          idType: kycData.documents.idType
        };
        
        // Convert files to base64
        if (kycData.documents.idFront) {
          documentsData.idFrontBase64 = await this.fileToBase64(kycData.documents.idFront);
          documentsData.idFrontFileName = kycData.documents.idFront.name;
          documentsData.idFrontFileType = kycData.documents.idFront.type;
        }
        
        if (kycData.documents.idBack) {
          documentsData.idBackBase64 = await this.fileToBase64(kycData.documents.idBack);
          documentsData.idBackFileName = kycData.documents.idBack.name;
          documentsData.idBackFileType = kycData.documents.idBack.type;
        }
      }

      // Submit all KYC data in one call (server expects PascalCase)
      const submissionData = {
        PersonalInfo: kycData.personalInfo,
        Address: kycData.address,
        Identity: kycData.identity,
        Documents: documentsData,
        FinancialProfile: kycData.financialProfile,
        Agreements: kycData.agreements,
        BankAccount: kycData.bankAccount
      };

      const response = await api.post('/kyc/submit', submissionData);
      return response.data;
    } catch (error: any) {
      console.error('KYC submission error:', error);
      return {
        success: false,
        message: error.response?.data?.detail || error.message || 'Failed to submit KYC'
      };
    }
  }

  private async fileToBase64(file: File): Promise<string> {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = () => {
        const result = reader.result as string;
        // Extract base64 data without the data URL prefix
        const base64 = result.split(',')[1];
        resolve(base64);
      };
      reader.onerror = reject;
      reader.readAsDataURL(file);
    });
  }

  // Helper to check if user needs to complete KYC
  isKycRequired(status: string): boolean {
    // Users who have submitted KYC (UnderReview) or are Approved don't need to complete KYC
    return status !== 'Approved' && status !== 'UnderReview';
  }

  // Helper to check if user can access trading features
  canTrade(status: string): boolean {
    return status === 'Approved';
  }

  // Map step names between frontend and backend
  mapStepName(step: string): string {
    const stepMap: Record<string, string> = {
      'personalInfo': 'personalinfo',
      'address': 'address',
      'identity': 'identity',
      'documents': 'documents',
      'financialProfile': 'financialprofile',
      'agreements': 'agreements',
      'bankAccount': 'bankaccount'
    };
    return stepMap[step] || step;
  }
}

export const kycService = new KycService();