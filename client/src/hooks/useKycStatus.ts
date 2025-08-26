import { useEffect } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { kycService } from '../services/kycService';

// Paths that don't require KYC approval
const KYC_EXEMPT_PATHS = [
  '/login',
  '/register',
  '/terms',
  '/privacy',
  '/',
  '/onboarding',
];

export function useKycStatus() {
  const { user, isAuthenticated } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();

  useEffect(() => {
    if (!isAuthenticated || !user) return;

    const currentPath = location.pathname;
    
    // Check if current path is exempt from KYC
    const isExemptPath = KYC_EXEMPT_PATHS.some(path => currentPath === path);
    
    if (!isExemptPath && kycService.isKycRequired(user.kycStatus)) {
      // User needs to complete KYC
      navigate('/register', { 
        state: { 
          message: 'Please complete your KYC verification to access trading features.',
          resumeKyc: true 
        } 
      });
    }
  }, [user, isAuthenticated, location, navigate]);

  return {
    kycStatus: user?.kycStatus,
    isKycRequired: user ? kycService.isKycRequired(user.kycStatus) : false,
    canTrade: user ? kycService.canTrade(user.kycStatus) : false,
  };
}