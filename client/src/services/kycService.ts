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
    const response = await api.post('/kyc/submit', kycData);
    return response.data;
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