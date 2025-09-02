import React, { useState, useEffect } from 'react';
import { useBankingModal } from '../../contexts/BankingModalContext';
import { fundingService } from '../../services/fundingService';
import type { BankAccount } from '../../services/fundingService';
import { DepositFundsModal } from './DepositFundsModal';
import { BankManagementModal } from './BankManagementModal';
import { TransferHistoryModal } from './TransferHistoryModal';
import { LinkAlpacaAccountModal } from './LinkAlpacaAccountModal';

export const BankingModals: React.FC = () => {
  const {
    showDepositModal,
    showBankManagementModal,
    showTransferHistoryModal,
    showLinkAlpacaModal,
    closeDepositModal,
    closeBankManagementModal,
    closeTransferHistoryModal,
    closeLinkAlpacaModal,
    onBankingDataChanged,
  } = useBankingModal();

  const [bankAccounts, setBankAccounts] = useState<BankAccount[]>([]);

  // Load bank accounts when modals open
  useEffect(() => {
    if (showDepositModal || showBankManagementModal) {
      loadBankAccounts();
    }
  }, [showDepositModal, showBankManagementModal]);

  const loadBankAccounts = async () => {
    try {
      const accounts = await fundingService.getBankAccounts();
      setBankAccounts(accounts);
    } catch (error) {
      console.error('Error loading bank accounts:', error);
      setBankAccounts([]);
    }
  };

  const handleDepositSuccess = () => {
    loadBankAccounts();
    onBankingDataChanged?.();
  };

  const handleBankAccountsUpdated = () => {
    loadBankAccounts();
    onBankingDataChanged?.();
  };

  const handleAlpacaAccountLinked = () => {
    onBankingDataChanged?.();
  };

  return (
    <>
      <DepositFundsModal
        isOpen={showDepositModal}
        onClose={closeDepositModal}
        bankAccounts={bankAccounts}
        onDepositSuccess={handleDepositSuccess}
      />
      
      <BankManagementModal
        isOpen={showBankManagementModal}
        onClose={closeBankManagementModal}
        onBankAccountsUpdated={handleBankAccountsUpdated}
      />
      
      <TransferHistoryModal
        isOpen={showTransferHistoryModal}
        onClose={closeTransferHistoryModal}
      />
      
      <LinkAlpacaAccountModal
        isOpen={showLinkAlpacaModal}
        onClose={closeLinkAlpacaModal}
        onSuccess={handleAlpacaAccountLinked}
      />
    </>
  );
};