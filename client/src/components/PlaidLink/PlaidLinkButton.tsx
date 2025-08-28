import React, { useCallback, useEffect, useState } from 'react';
import { usePlaidLink } from 'react-plaid-link';
import { fundingService } from '../../services/fundingService';
import { useAuth } from '../../contexts/AuthContext';

interface PlaidLinkButtonProps {
  onSuccess: () => void;
  onExit?: () => void;
}

export const PlaidLinkButton: React.FC<PlaidLinkButtonProps> = ({ onSuccess, onExit }) => {
  const [token, setToken] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const { user } = useAuth();

  // Fetch Link token from backend
  useEffect(() => {
    const createLinkToken = async () => {
      if (!user) return;
      
      setLoading(true);
      setError(null);
      
      try {
        const response = await fundingService.createPlaidLinkToken({
          userId: user.id,
          userEmail: user.email
        });
        
        setToken(response.link_token || response.linkToken || null);
      } catch (err: any) {
        console.error('Error creating link token:', err);
        setError(err.response?.data?.message || 'Failed to initialize bank connection');
      } finally {
        setLoading(false);
      }
    };

    createLinkToken();
  }, [user]);

  const onPlaidSuccess = useCallback(
    async (public_token: string, metadata: any) => {
      console.log('Plaid Link success:', { public_token, metadata });
      
      setLoading(true);
      setError(null);
      
      try {
        // Get the selected account from metadata
        const selectedAccount = metadata.accounts[0];
        
        // Create ACH relationship with Alpaca
        await fundingService.createAchRelationship({
          publicToken: public_token,
          accountId: selectedAccount.id
        });
        
        // Notify parent component of success
        onSuccess();
      } catch (err: any) {
        console.error('Error creating ACH relationship:', err);
        setError(err.response?.data?.message || 'Failed to link bank account');
      } finally {
        setLoading(false);
      }
    },
    [onSuccess]
  );

  const config = {
    token,
    onSuccess: onPlaidSuccess,
    onExit: onExit,
  };

  const { open, ready, error: plaidError } = usePlaidLink(config);

  const handleClick = () => {
    if (!token) {
      setError('Bank connection not ready. Please try again.');
      return;
    }
    
    open();
  };

  if (plaidError) {
    console.error('Plaid Link error:', plaidError);
  }

  return (
    <div className="w-full">
      {error && (
        <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-md">
          <p className="text-sm text-red-600">{error}</p>
        </div>
      )}
      
      <button
        onClick={handleClick}
        disabled={!ready || loading || !token}
        className={`
          w-full px-4 py-3 rounded-md font-medium transition-colors
          ${ready && token && !loading
            ? 'bg-blue-600 text-white hover:bg-blue-700'
            : 'bg-gray-300 text-gray-500 cursor-not-allowed'
          }
        `}
      >
        {loading ? (
          <span className="flex items-center justify-center">
            <svg className="animate-spin -ml-1 mr-3 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
              <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
              <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
            </svg>
            {token ? 'Processing...' : 'Initializing...'}
          </span>
        ) : (
          'Link Bank Account'
        )}
      </button>
      
      <p className="mt-2 text-xs text-gray-500 text-center">
        Securely connect your bank account using Plaid
      </p>
    </div>
  );
};