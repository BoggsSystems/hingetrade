import React, { createContext, useContext, useState, ReactNode } from 'react';

interface BankingModalContextType {
  // Modal visibility state
  showDepositModal: boolean;
  showBankManagementModal: boolean;
  showTransferHistoryModal: boolean;
  showLinkAlpacaModal: boolean;
  
  // Modal control functions
  openDepositModal: () => void;
  closeDepositModal: () => void;
  openBankManagementModal: () => void;
  closeBankManagementModal: () => void;
  openTransferHistoryModal: () => void;
  closeTransferHistoryModal: () => void;
  openLinkAlpacaModal: () => void;
  closeLinkAlpacaModal: () => void;
  
  // Data refresh callback
  onBankingDataChanged?: () => void;
  setOnBankingDataChanged: (callback: (() => void) | undefined) => void;
}

const BankingModalContext = createContext<BankingModalContextType | undefined>(undefined);

interface BankingModalProviderProps {
  children: ReactNode;
}

export const BankingModalProvider: React.FC<BankingModalProviderProps> = ({ children }) => {
  const [showDepositModal, setShowDepositModal] = useState(false);
  const [showBankManagementModal, setShowBankManagementModal] = useState(false);
  const [showTransferHistoryModal, setShowTransferHistoryModal] = useState(false);
  const [showLinkAlpacaModal, setShowLinkAlpacaModal] = useState(false);
  const [onBankingDataChanged, setOnBankingDataChanged] = useState<(() => void) | undefined>();

  const openDepositModal = () => setShowDepositModal(true);
  const closeDepositModal = () => setShowDepositModal(false);
  
  const openBankManagementModal = () => setShowBankManagementModal(true);
  const closeBankManagementModal = () => setShowBankManagementModal(false);
  
  const openTransferHistoryModal = () => setShowTransferHistoryModal(true);
  const closeTransferHistoryModal = () => setShowTransferHistoryModal(false);
  
  const openLinkAlpacaModal = () => setShowLinkAlpacaModal(true);
  const closeLinkAlpacaModal = () => setShowLinkAlpacaModal(false);

  const value: BankingModalContextType = {
    showDepositModal,
    showBankManagementModal,
    showTransferHistoryModal,
    showLinkAlpacaModal,
    openDepositModal,
    closeDepositModal,
    openBankManagementModal,
    closeBankManagementModal,
    openTransferHistoryModal,
    closeTransferHistoryModal,
    openLinkAlpacaModal,
    closeLinkAlpacaModal,
    onBankingDataChanged,
    setOnBankingDataChanged,
  };

  return (
    <BankingModalContext.Provider value={value}>
      {children}
    </BankingModalContext.Provider>
  );
};

export const useBankingModal = () => {
  const context = useContext(BankingModalContext);
  if (!context) {
    throw new Error('useBankingModal must be used within a BankingModalProvider');
  }
  return context;
};