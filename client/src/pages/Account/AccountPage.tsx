import React, { useState, useEffect } from 'react';
import { useAuth } from '../../contexts/AuthContext';
import { fundingService } from '../../services/fundingService';
import type { BankAccount, Transfer } from '../../services/fundingService';
import { PlaidLinkButton } from '../../components/PlaidLink/PlaidLinkButton';
import styles from './AccountPage.module.css';

type TabType = 'profile' | 'banking' | 'settings';

const AccountPage: React.FC = () => {
  const { user } = useAuth();
  const [activeTab, setActiveTab] = useState<TabType>('banking');

  return (
    <div className={styles.container}>
      <div className={styles.header}>
        <h1>Account</h1>
      </div>

      <div className={styles.tabs}>
        <button
          className={`${styles.tab} ${activeTab === 'profile' ? styles.active : ''}`}
          onClick={() => setActiveTab('profile')}
        >
          Profile
        </button>
        <button
          className={`${styles.tab} ${activeTab === 'banking' ? styles.active : ''}`}
          onClick={() => setActiveTab('banking')}
        >
          Banking & Funding
        </button>
        <button
          className={`${styles.tab} ${activeTab === 'settings' ? styles.active : ''}`}
          onClick={() => setActiveTab('settings')}
        >
          Settings
        </button>
      </div>

      <div className={styles.content}>
        {activeTab === 'profile' && (
          <div className={styles.profileSection}>
            <h2>Profile Information</h2>
            <div className={styles.infoGrid}>
              <div className={styles.infoItem}>
                <label>Username</label>
                <p>{user?.username}</p>
              </div>
              <div className={styles.infoItem}>
                <label>Email</label>
                <p>{user?.email}</p>
              </div>
              <div className={styles.infoItem}>
                <label>KYC Status</label>
                <p className={`${styles.kycStatus} ${styles[user?.kycStatus?.toLowerCase() || '']}`}>
                  {user?.kycStatus || 'Not Started'}
                </p>
              </div>
            </div>
          </div>
        )}

        {activeTab === 'banking' && (
          <BankingSection />
        )}

        {activeTab === 'settings' && (
          <div className={styles.settingsSection}>
            <h2>Account Settings</h2>
            <p>Settings options coming soon...</p>
          </div>
        )}
      </div>
    </div>
  );
};

// Banking Section Component
const BankingSection: React.FC = () => {
  // const { user } = useAuth(); // Currently not used but may be needed later
  const [showDepositForm, setShowDepositForm] = useState(false);
  const [depositAmount, setDepositAmount] = useState('');
  const [isProcessing, setIsProcessing] = useState(false);
  const [bankAccounts, setBankAccounts] = useState<BankAccount[]>([]);
  const [transfers, setTransfers] = useState<Transfer[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    loadBankingData();
  }, []);

  const loadBankingData = async () => {
    try {
      setIsLoading(true);
      const [accountsData, transfersData] = await Promise.all([
        fundingService.getBankAccounts().catch(() => []),
        fundingService.getTransfers().catch(() => [])
      ]);
      setBankAccounts(accountsData);
      setTransfers(transfersData);
    } catch (err) {
      console.error('Error loading banking data:', err);
      setError('Failed to load banking information');
    } finally {
      setIsLoading(false);
    }
  };

  const handleDeposit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!depositAmount || parseFloat(depositAmount) <= 0) return;

    // Find active bank account
    const activeBank = bankAccounts.find(bank => bank.status === 'ACTIVE') || bankAccounts[0];
    
    if (!activeBank) {
      alert('No active bank account found. Please link a bank account first.');
      return;
    }

    setIsProcessing(true);
    try {
      const result = await fundingService.initiateAchTransfer({
        amount: parseFloat(depositAmount),
        direction: 'INCOMING',
        relationshipId: activeBank.id
      });
      
      // Show success message
      if (result.message) {
        alert(result.message);
      }
      
      setDepositAmount('');
      setShowDepositForm(false);
      
      // Reload transfers
      loadBankingData();
    } catch (error: any) {
      console.error('Deposit failed:', error);
      const errorMessage = error.response?.data?.message || 'Failed to initiate deposit. Please try again.';
      alert(errorMessage);
    } finally {
      setIsProcessing(false);
    }
  };

  return (
    <div className={styles.bankingSection}>
      <div className={styles.bankingHeader}>
        <h2>Banking & Funding</h2>
        {bankAccounts.length > 0 ? (
          <button 
            className={styles.primaryButton}
            onClick={() => setShowDepositForm(!showDepositForm)}
          >
            {showDepositForm ? 'Cancel' : 'Deposit Funds'}
          </button>
        ) : (
          <PlaidLinkButton 
            onSuccess={() => {
              loadBankingData();
              setShowDepositForm(false);
            }}
            onExit={() => {
              console.log('Plaid Link exited');
            }}
          />
        )}
      </div>

      {showDepositForm && (
        <form onSubmit={handleDeposit} className={styles.depositForm}>
          <h3>Deposit Funds</h3>
          <div className={styles.formGroup}>
            <label htmlFor="amount">Amount to Deposit</label>
            <div className={styles.amountInput}>
              <span className={styles.currencySymbol}>$</span>
              <input
                id="amount"
                type="number"
                min="1"
                step="0.01"
                value={depositAmount}
                onChange={(e) => setDepositAmount(e.target.value)}
                placeholder="0.00"
                required
                disabled={isProcessing}
              />
            </div>
          </div>
          
          <div className={styles.bankInfo}>
            {bankAccounts.length > 0 && (
              <p><strong>From:</strong> {bankAccounts[0].nickname || 'Bank Account'} ****{bankAccounts[0].bankAccountNumber?.slice(-4) || ''}</p>
            )}
            <p className={styles.disclaimer}>
              ACH transfers typically take 3-5 business days to complete.
            </p>
          </div>

          <div className={styles.formActions}>
            <button 
              type="submit" 
              className={styles.submitButton}
              disabled={isProcessing || !depositAmount || parseFloat(depositAmount) <= 0}
            >
              {isProcessing ? 'Processing...' : `Deposit $${depositAmount || '0'}`}
            </button>
          </div>
        </form>
      )}

      <div className={styles.section}>
        <h3>Linked Bank Accounts</h3>
        {isLoading ? (
          <div className={styles.loading}>Loading bank accounts...</div>
        ) : bankAccounts.length === 0 ? (
          <div className={styles.noBankAccounts}>
            <p>No bank accounts linked yet</p>
            <div className={styles.plaidLinkWrapper}>
              <PlaidLinkButton 
                onSuccess={() => {
                  loadBankingData();
                  setShowDepositForm(false);
                }}
                onExit={() => {
                  console.log('Plaid Link exited');
                }}
              />
            </div>
          </div>
        ) : (
          <>
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
                </div>
                <div className={styles.bankActions}>
                  <span className={`${styles.bankStatus} ${styles[account.status.toLowerCase()]}`}>
                    {account.status}
                  </span>
                </div>
              </div>
            ))}
            <div className={styles.addBankWrapper}>
              <PlaidLinkButton 
                onSuccess={() => {
                  loadBankingData();
                }}
                onExit={() => {
                  console.log('Plaid Link exited');
                }}
              />
            </div>
          </>
        )}
      </div>

      <div className={styles.section}>
        <h3>Recent Transfers</h3>
        {isLoading ? (
          <div className={styles.loading}>Loading transfers...</div>
        ) : error ? (
          <div className={styles.error}>{error}</div>
        ) : (
          <div className={styles.transferList}>
            {transfers.length === 0 ? (
              <div className={styles.noTransfers}>
                <p>No transfers yet</p>
                <p className={styles.subtext}>Your transfer history will appear here</p>
              </div>
            ) : (
              transfers.map((transfer) => (
                <div key={transfer.id} className={styles.transferItem}>
                  <div className={styles.transferDetails}>
                    <div className={styles.transferHeader}>
                      <span className={styles.transferType}>
                        {transfer.direction === 'INCOMING' ? 'Deposit' : 'Withdrawal'}
                      </span>
                      <span className={`${styles.transferStatus} ${styles[transfer.status.toLowerCase()]}`}>
                        {transfer.status}
                      </span>
                    </div>
                    <div className={styles.transferAmount}>
                      ${parseFloat(transfer.amount).toLocaleString('en-US', { minimumFractionDigits: 2 })}
                    </div>
                    <div className={styles.transferDate}>
                      {new Date(transfer.createdAt).toLocaleDateString('en-US', {
                        month: 'short',
                        day: 'numeric',
                        year: 'numeric',
                        hour: '2-digit',
                        minute: '2-digit'
                      })}
                    </div>
                  </div>
                  <div className={styles.transferArrow}>
                    {transfer.direction === 'INCOMING' ? (
                      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                        <path d="M12 5V19" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                        <path d="M5 12L12 19L19 12" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                      </svg>
                    ) : (
                      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                        <path d="M12 19V5" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                        <path d="M5 12L12 5L19 12" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                      </svg>
                    )}
                  </div>
                </div>
              ))
            )}
          </div>
        )}
      </div>
    </div>
  );
};

export default AccountPage;