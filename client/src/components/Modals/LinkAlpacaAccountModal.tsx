import React, { useState } from 'react';
import { useAuth } from '../../contexts/AuthContext';
import styles from './LinkAlpacaAccountModal.module.css';

interface LinkAlpacaAccountModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess: () => void;
}

export const LinkAlpacaAccountModal: React.FC<LinkAlpacaAccountModalProps> = ({
  isOpen,
  onClose,
  onSuccess,
}) => {
  const [apiKeyId, setApiKeyId] = useState('');
  const [apiSecret, setApiSecret] = useState('');
  const [environment, setEnvironment] = useState('paper');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const { getAccessToken } = useAuth();

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);
    setError(null);

    try {
      const token = await getAccessToken();
      if (!token) {
        throw new Error('No access token available');
      }

      const apiBaseUrl = import.meta.env.VITE_API_URL || 'http://localhost:5001/api';
      const response = await fetch(`${apiBaseUrl}/account/link`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          ApiKeyId: apiKeyId,
          ApiSecret: apiSecret,
          Env: environment,
          IsBrokerApi: environment === 'paper'
        }),
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.details || `Failed to link account: ${response.status}`);
      }

      const result = await response.json();
      console.log('Account linked successfully:', result);
      
      // Clear form
      setApiKeyId('');
      setApiSecret('');
      setEnvironment('paper');
      
      onSuccess();
      onClose();
    } catch (err) {
      console.error('Error linking account:', err);
      setError(err instanceof Error ? err.message : 'Failed to link account');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleClose = () => {
    if (!isSubmitting) {
      setError(null);
      onClose();
    }
  };

  return (
    <div className={styles.overlay} onClick={handleClose}>
      <div className={styles.modal} onClick={(e) => e.stopPropagation()}>
        <div className={styles.header}>
          <h2>Link Alpaca Account</h2>
          <button
            className={styles.closeButton}
            onClick={handleClose}
            disabled={isSubmitting}
          >
            ×
          </button>
        </div>

        <form onSubmit={handleSubmit} className={styles.content}>
          {error && (
            <div className={styles.error}>
              {error}
            </div>
          )}

          <div className={styles.info}>
            <p>Connect your Alpaca trading account to place orders and manage positions.</p>
            <p><strong>Your credentials are encrypted and stored securely.</strong></p>
          </div>

          <div className={styles.formGroup}>
            <label htmlFor="environment">Environment</label>
            <select
              id="environment"
              value={environment}
              onChange={(e) => setEnvironment(e.target.value)}
              disabled={isSubmitting}
              className={styles.select}
            >
              <option value="paper">Paper Trading (Sandbox)</option>
              <option value="live">Live Trading</option>
            </select>
          </div>

          <div className={styles.formGroup}>
            <label htmlFor="apiKeyId">API Key ID</label>
            <input
              type="text"
              id="apiKeyId"
              value={apiKeyId}
              onChange={(e) => setApiKeyId(e.target.value)}
              required
              disabled={isSubmitting}
              className={styles.input}
              placeholder="Your Alpaca API Key ID"
            />
          </div>

          <div className={styles.formGroup}>
            <label htmlFor="apiSecret">API Secret</label>
            <input
              type="password"
              id="apiSecret"
              value={apiSecret}
              onChange={(e) => setApiSecret(e.target.value)}
              required
              disabled={isSubmitting}
              className={styles.input}
              placeholder="Your Alpaca API Secret"
            />
          </div>

          <div className={styles.helpText}>
            <p>Get your API credentials from your <a href="https://alpaca.markets/account" target="_blank" rel="noopener noreferrer">Alpaca account dashboard</a>.</p>
            <p>For testing, use Paper Trading credentials which are separate from your live account.</p>
          </div>

          <div className={styles.actions}>
            <button
              type="button"
              onClick={handleClose}
              disabled={isSubmitting}
              className={styles.cancelButton}
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={isSubmitting}
              className={styles.submitButton}
            >
              {isSubmitting ? 'Linking...' : 'Link Account'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};