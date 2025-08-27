import { api } from './api';

export interface BankAccount {
  id: string;
  accountId: string;
  status: string;
  accountOwnerName: string;
  bankAccountType: string;
  bankAccountNumber: string;
  bankRoutingNumber: string;
  nickname?: string;
  createdAt: string;
  updatedAt: string;
}

export interface Transfer {
  id: string;
  accountId: string;
  type: string;
  status: string;
  amount: string;
  direction: string;
  relationshipId?: string;
  reason?: string;
  createdAt: string;
  updatedAt: string;
  expiresAt?: string;
}

export interface AchTransferRequest {
  amount: number;
  direction: 'INCOMING' | 'OUTGOING';
  relationshipId?: string;
}

export interface AchTransferResponse {
  transferId: string;
  status: string;
  amount: number;
  direction: string;
  initiatedAt: string;
  message: string;
}

export const fundingService = {
  async getBankAccounts(): Promise<BankAccount[]> {
    const response = await api.get<BankAccount[]>('/funding/bank-accounts');
    return response.data;
  },

  async initiateAchTransfer(request: AchTransferRequest): Promise<AchTransferResponse> {
    const response = await api.post<AchTransferResponse>('/funding/transfers/ach', request);
    return response.data;
  },

  async getTransfers(): Promise<Transfer[]> {
    const response = await api.get<Transfer[]>('/funding/transfers');
    return response.data;
  },

  async getTransferStatus(transferId: string): Promise<Transfer> {
    const response = await api.get<Transfer>(`/funding/transfers/${transferId}`);
    return response.data;
  },
};