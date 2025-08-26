import { useAuth } from '../contexts/AuthContext';
import { kycService } from '../services/kycService';

export function useKycStatus() {
  const { user } = useAuth();

  return {
    kycStatus: user?.kycStatus,
    isKycRequired: user ? kycService.isKycRequired(user.kycStatus) : false,
    canTrade: user ? kycService.canTrade(user.kycStatus) : false,
  };
}