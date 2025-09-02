import React, { useState, useEffect } from 'react';
import { PlaidLinkButton } from '../PlaidLink/PlaidLinkButton';
import { fundingService } from '../../services/fundingService';
import type { BankAccount } from '../../services/fundingService';
import styles from './BankManagementModal.module.css';

interface BankManagementModalProps {
  isOpen: boolean;
  onClose: () => void;
  onBankAccountsUpdated: () => void;
}

export const BankManagementModal: React.FC<BankManagementModalProps> = ({
  isOpen,
  onClose,
  onBankAccountsUpdated,
}) => {
  const [bankAccounts, setBankAccounts] = useState<BankAccount[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (isOpen) {
      loadBankAccounts();
    }
  }, [isOpen]);

  const loadBankAccounts = async () => {
    try {
      setIsLoading(true);
      setError(null);
      const accounts = await fundingService.getBankAccounts();
      setBankAccounts(accounts);
    } catch (err) {
      console.error('Error loading bank accounts:', err);
      setError('Failed to load bank accounts');
    } finally {
      setIsLoading(false);
    }
  };

  const handlePlaidSuccess = () => {
    loadBankAccounts();
    onBankAccountsUpdated();
  };

  const handleClose = () => {
    setError(null);
    onClose();
  };

  if (!isOpen) return null;

  return (
    <div className={styles.overlay} onClick={handleClose}>
      <div className={styles.modal} onClick={(e) => e.stopPropagation()}>
        <div className={styles.header}>
          <h2>Bank Account Management</h2>
          <button onClick={handleClose} className={styles.closeButton}>
            ×
          </button>
        </div>

        <div className={styles.content}>
          {error && (
            <div className={styles.error}>
              {error}
            </div>
          )}

          <div className={styles.section}>
            <div className={styles.sectionHeader}>
              <h3>Linked Bank Accounts</h3>
              <div className={styles.plaidLinkWrapper}>
                <PlaidLinkButton 
                  onSuccess={handlePlaidSuccess}
                  onExit={() => {
                    console.log('Plaid Link exited');
                  }}
                />
              </div>
            </div>

            {isLoading ? (
              <div className={styles.loading}>
                <div className={styles.loadingSpinner}></div>
                Loading bank accounts...
              </div>
            ) : bankAccounts.length === 0 ? (
              <div className={styles.noBankAccounts}>
                <div className={styles.emptyState}>
                  <svg width="48" height="48" viewBox="0 0 24 24" fill="none" className={styles.emptyIcon}>
                    <rect x="3" y="6" width="18" height="12" rx="2" stroke="currentColor" strokeWidth="2"/>
                    <path d="M3 10H21" stroke="currentColor" strokeWidth="2"/>
                  </svg>
                  <p>No bank accounts linked yet</p>
                  <p className={styles.emptySubtext}>Link your bank account to start funding your trading account</p>
                </div>
              </div>
            ) : (
              <div className={styles.bankAccountsList}>
                {bankAccounts.map((account) => (
                  <div key={account.id} className={styles.bankAccount}>
                    <div className={styles.bankIcon}>
                      <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                        <rect x="3" y="6" width="18" height="12" rx="2" stroke="currentColor" strokeWidth="2"/>
                        <path d="M3 10H21" stroke="currentColor" strokeWidth="2"/>
                      </svg>
                    </div>
                    <div className={styles.bankDetails}>
                      <p className={styles.bankName}>{account.nickname || 'Bank Account'}</p>
                      <p className={styles.accountNumber}>
                        {account.bankAccountType} ****{account.bankAccountNumber?.slice(-4) || ''}
                      </p>
                      <p className={styles.accountInfo}>
                        Added {new Date(account.createdAt).toLocaleDateString()}
                      </p>
                    </div>
                    <div className={styles.bankActions}>
                      <span className={`${styles.bankStatus} ${styles[account.status.toLowerCase()]}`}>
                        {account.status}
                      </span>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>

          <div className={styles.infoSection}>
            <h4>Security Information</h4>
            <div className={styles.infoGrid}>
              <div className={styles.infoItem}>
                <strong>Bank-level security</strong>
                <p>Your bank credentials are encrypted using bank-level security through Plaid</p>
              </div>
              <div className={styles.infoItem}>
                <strong>Read-only access</strong>
                <p>We can only read account information, not make transactions from your bank</p>
              </div>
              <div className={styles.infoItem}>
                <strong>Secure transfers</strong>
                <p>All transfers are processed through regulated ACH networks</p>
              </div>
            </div>
          </div>
        </div>

        <div className={styles.footer}>
          <button onClick={handleClose} className={styles.closeFooterButton}>
            Close
          </button>
        </div>
      </div>
    </div>
  );
};