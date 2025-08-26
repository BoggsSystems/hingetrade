import { api } from './api';
import type { KYCData } from '../components/Onboarding/KYCOnboardingModal';

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
    await api.post(`/kyc/progress/${step}`, { data });
  }

  async submitKyc(kycData: KYCData): Promise<{ success: boolean; message: string }> {
    // Convert document files to base64 before submission
    const preparedData = { ...kycData };
    
    if (kycData.documents) {
      const documents: any = {
        idType: kycData.documents.idType
      };
      
      // Convert files to base64
      if (kycData.documents.idFront) {
        documents.idFrontBase64 = await this.fileToBase64(kycData.documents.idFront);
        documents.idFrontFileName = kycData.documents.idFront.name;
        documents.idFrontFileType = kycData.documents.idFront.type;
      }
      
      if (kycData.documents.idBack) {
        documents.idBackBase64 = await this.fileToBase64(kycData.documents.idBack);
        documents.idBackFileName = kycData.documents.idBack.name;
        documents.idBackFileType = kycData.documents.idBack.type;
      }
      
      preparedData.documents = documents;
    }
    
    const response = await api.post('/kyc/submit', preparedData);
    return response.data;
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
    return status !== 'Approved';
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