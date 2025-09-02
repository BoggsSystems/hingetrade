import React, { useState } from 'react';
import { fundingService } from '../../services/fundingService';
import type { BankAccount } from '../../services/fundingService';
import styles from './DepositFundsModal.module.css';

interface DepositFundsModalProps {
  isOpen: boolean;
  onClose: () => void;
  bankAccounts: BankAccount[];
  onDepositSuccess: () => void;
}

export const DepositFundsModal: React.FC<DepositFundsModalProps> = ({
  isOpen,
  onClose,
  bankAccounts,
  onDepositSuccess,
}) => {
  const [depositAmount, setDepositAmount] = useState('');
  const [selectedBankId, setSelectedBankId] = useState('');
  const [isProcessing, setIsProcessing] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const activeBanks = bankAccounts.filter(bank => bank.status === 'ACTIVE');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!depositAmount || parseFloat(depositAmount) <= 0) return;

    const selectedBank = activeBanks.find(bank => bank.id === selectedBankId) || activeBanks[0];
    
    if (!selectedBank) {
      setError('No active bank account found. Please link a bank account first.');
      return;
    }

    setIsProcessing(true);
    setError(null);
    
    try {
      const result = await fundingService.initiateAchTransfer({
        amount: parseFloat(depositAmount),
        direction: 'INCOMING',
        relationshipId: selectedBank.id
      });
      
      if (result.message) {
        alert(result.message);
      }
      
      setDepositAmount('');
      setSelectedBankId('');
      onDepositSuccess();
      onClose();
    } catch (error: any) {
      console.error('Deposit failed:', error);
      const errorMessage = error.response?.data?.message || 'Failed to initiate deposit. Please try again.';
      setError(errorMessage);
    } finally {
      setIsProcessing(false);
    }
  };

  const handleClose = () => {
    setDepositAmount('');
    setSelectedBankId('');
    setError(null);
    onClose();
  };

  if (!isOpen) return null;

  return (
    <div className={styles.overlay} onClick={handleClose}>
      <div className={styles.modal} onClick={(e) => e.stopPropagation()}>
        <div className={styles.header}>
          <h2>Deposit Funds</h2>
          <button onClick={handleClose} className={styles.closeButton}>
            ×
          </button>
        </div>

        <form onSubmit={handleSubmit} className={styles.form}>
          {error && (
            <div className={styles.error}>
              {error}
            </div>
          )}

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
                autoFocus
              />
            </div>
          </div>

          {activeBanks.length > 1 && (
            <div className={styles.formGroup}>
              <label htmlFor="bankAccount">From Bank Account</label>
              <select
                id="bankAccount"
                value={selectedBankId}
                onChange={(e) => setSelectedBankId(e.target.value)}
                className={styles.bankSelect}
                disabled={isProcessing}
              >
                {activeBanks.map((bank) => (
                  <option key={bank.id} value={bank.id}>
                    {bank.nickname || 'Bank Account'} ****{bank.bankAccountNumber?.slice(-4) || ''}
                  </option>
                ))}
              </select>
            </div>
          )}

          {activeBanks.length > 0 && (
            <div className={styles.bankInfo}>
              <p>
                <strong>From:</strong> {
                  selectedBankId 
                    ? activeBanks.find(b => b.id === selectedBankId)?.nickname || 'Bank Account'
                    : activeBanks[0]?.nickname || 'Bank Account'
                } ****{
                  selectedBankId
                    ? activeBanks.find(b => b.id === selectedBankId)?.bankAccountNumber?.slice(-4) || ''
                    : activeBanks[0]?.bankAccountNumber?.slice(-4) || ''
                }
              </p>
              <p className={styles.disclaimer}>
                ACH transfers typically take 3-5 business days to complete.
              </p>
            </div>
          )}

          <div className={styles.formActions}>
            <button
              type="button"
              onClick={handleClose}
              className={styles.cancelButton}
              disabled={isProcessing}
            >
              Cancel
            </button>
            <button 
              type="submit" 
              className={styles.submitButton}
              disabled={isProcessing || !depositAmount || parseFloat(depositAmount) <= 0 || activeBanks.length === 0}
            >
              {isProcessing ? 'Processing...' : `Deposit $${depositAmount || '0'}`}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};