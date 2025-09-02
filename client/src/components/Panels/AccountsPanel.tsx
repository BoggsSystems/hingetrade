import React, { useState, useEffect } from 'react';
import type { IPanelComponentProps } from '../../types/panel';
import { useAuth } from '../../contexts/AuthContext';
import { fundingService } from '../../services/fundingService';
import type { BankAccount, Transfer } from '../../services/fundingService';
import { DepositFundsModal } from '../Modals/DepositFundsModal';
import { BankManagementModal } from '../Modals/BankManagementModal';
import { TransferHistoryModal } from '../Modals/TransferHistoryModal';
import './Panels.css';

export interface AccountData {
  id: string;
  account_number: string;
  status: 'ACTIVE' | 'ACCOUNT_CLOSED' | 'ACCOUNT_RESTRICTED';
  currency: string;
  buying_power: string;
  regt_buying_power: string;
  daytrading_buying_power: string;
  non_marginable_buying_power: string;
  cash: string;
  cash_withdrawable: string;
  cash_transferable: string;
  pending_transfer_out: string;
  pending_transfer_in: string;
  portfolio_value: string;
  equity: string;
  last_equity: string;
  multiplier: string;
  long_market_value: string;
  short_market_value: string;
  initial_margin: string;
  maintenance_margin: string;
  last_maintenance_margin: string;
  sma: string;
  daytrade_count: number;
  balance_asof: string;
  trade_suspended_by_user: boolean;
  trading_blocked: boolean;
  transfers_blocked: boolean;
  account_blocked: boolean;
  created_at: string;
  pattern_day_trader: boolean;
  accrued_fees: string;
  pending_reg_taf_fees: string;
}


type TabType = 'overview' | 'banking';

const AccountsPanel: React.FC<IPanelComponentProps> = ({
  config,
  onReady,
}) => {
  const [accountData, setAccountData] = useState<AccountData | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [lastRefresh, setLastRefresh] = useState<Date>(new Date());
  const { getAccessToken } = useAuth();
  
  // Tab state
  const [activeTab, setActiveTab] = useState<TabType>('overview');
  
  // Banking-related state
  const [bankAccounts, setBankAccounts] = useState<BankAccount[]>([]);
  const [recentTransfers, setRecentTransfers] = useState<Transfer[]>([]);
  const [bankingLoading, setBankingLoading] = useState(true);
  
  // Modal state
  const [showDepositModal, setShowDepositModal] = useState(false);
  const [showBankModal, setShowBankModal] = useState(false);
  const [showTransferModal, setShowTransferModal] = useState(false);

  useEffect(() => {
    onReady?.();
  }, [onReady]);

  useEffect(() => {
    fetchAccountData();
    fetchBankingData();
    // Set up refresh interval every 30 seconds
    const interval = setInterval(() => {
      fetchAccountData();
      fetchBankingData();
    }, 30000);
    return () => clearInterval(interval);
  }, []);

  const fetchAccountData = async () => {
    setIsLoading(true);
    setError(null);

    try {
      const token = await getAccessToken();
      if (!token) {
        throw new Error('No access token available');
      }

      const apiBaseUrl = import.meta.env.VITE_API_URL || 'http://localhost:5001/api';
      
      // Fetch account data
      const accountResponse = await fetch(`${apiBaseUrl}/account`, {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
      });

      if (!accountResponse.ok) {
        throw new Error(`Failed to fetch account data: ${accountResponse.statusText}`);
      }

      const accountData = await accountResponse.json();
      
      // Map backend AccountDto to frontend AccountData interface
      const mappedAccountData: AccountData = {
        id: 'api-account',
        account_number: accountData.AccountNumber || accountData.accountNumber,
        status: accountData.Status || accountData.status || 'ACTIVE',
        currency: 'USD',
        buying_power: (accountData.BuyingPower || accountData.buyingPower || 0).toString(),
        regt_buying_power: (accountData.BuyingPower || accountData.buyingPower || 0).toString(),
        daytrading_buying_power: (accountData.BuyingPower || accountData.buyingPower || 0).toString(),
        non_marginable_buying_power: (accountData.Cash || accountData.cash || 0).toString(),
        cash: (accountData.Cash || accountData.cash || 0).toString(),
        cash_withdrawable: (accountData.Cash || accountData.cash || 0).toString(),
        cash_transferable: (accountData.Cash || accountData.cash || 0).toString(),
        pending_transfer_out: '0.00',
        pending_transfer_in: '0.00',
        portfolio_value: (accountData.PortfolioValue || accountData.portfolioValue || 0).toString(),
        equity: (accountData.PortfolioValue || accountData.portfolioValue || 0).toString(), // Use PortfolioValue as equity
        last_equity: (accountData.PortfolioValue || accountData.portfolioValue || 0).toString(),
        multiplier: '1', // Default to cash account
        long_market_value: '0.00',
        short_market_value: '0.00',
        initial_margin: '0.00',
        maintenance_margin: '0.00',
        last_maintenance_margin: '0.00',
        sma: '0.00',
        daytrade_count: 0,
        balance_asof: new Date().toISOString(),
        trade_suspended_by_user: false,
        trading_blocked: accountData.TradingBlocked || accountData.tradingBlocked || false,
        transfers_blocked: accountData.TransfersBlocked || accountData.transfersBlocked || false,
        account_blocked: accountData.AccountBlocked || accountData.accountBlocked || false,
        created_at: new Date().toISOString(),
        pattern_day_trader: accountData.PatternDayTrader || accountData.patternDayTrader || false,
        accrued_fees: '0.00',
        pending_reg_taf_fees: '0.00'
      };
      
      setAccountData(mappedAccountData);

      // Portfolio history could be fetched here if needed for charts

      setLastRefresh(new Date());
    } catch (err) {
      console.error('Error fetching account data:', err);
      setError(err instanceof Error ? err.message : 'Failed to fetch account data');
      // Fallback to mock data for development
      const mockAccount = generateMockAccountData();
      setAccountData(mockAccount);
      setLastRefresh(new Date());
    } finally {
      setIsLoading(false);
    }
  };

  const generateMockAccountData = (): AccountData => ({
    id: 'mock-account-id',
    account_number: '••••••1234',
    status: 'ACTIVE',
    currency: 'USD',
    buying_power: '45750.25',
    regt_buying_power: '45750.25',
    daytrading_buying_power: '91500.50',
    non_marginable_buying_power: '22875.13',
    cash: '15250.75',
    cash_withdrawable: '15250.75',
    cash_transferable: '15250.75',
    pending_transfer_out: '0.00',
    pending_transfer_in: '0.00',
    portfolio_value: '78432.50',
    equity: '78432.50',
    last_equity: '77895.25',
    multiplier: '2',
    long_market_value: '63181.75',
    short_market_value: '0.00',
    initial_margin: '31590.88',
    maintenance_margin: '18954.53',
    last_maintenance_margin: '18698.81',
    sma: '39216.25',
    daytrade_count: 2,
    balance_asof: new Date().toISOString(),
    trade_suspended_by_user: false,
    trading_blocked: false,
    transfers_blocked: false,
    account_blocked: false,
    created_at: '2023-01-15T10:30:00Z',
    pattern_day_trader: false,
    accrued_fees: '12.50',
    pending_reg_taf_fees: '0.00'
  });


  const formatCurrency = (value: string | number | undefined | null) => {
    if (value === undefined || value === null) {
      return '$0.00';
    }
    const numValue = typeof value === 'string' ? parseFloat(value) : value;
    if (isNaN(numValue)) {
      return '$0.00';
    }
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 2
    }).format(numValue);
  };

  const formatPercent = (value: number) => {
    return `${value >= 0 ? '+' : ''}${value.toFixed(2)}%`;
  };

  const getDayPerformance = () => {
    if (!accountData) return { change: 0, changePercent: 0 };
    
    const currentEquity = parseFloat(accountData.equity || '0');
    const lastEquity = parseFloat(accountData.last_equity || '0');
    
    if (isNaN(currentEquity) || isNaN(lastEquity)) {
      return { change: 0, changePercent: 0 };
    }
    
    const change = currentEquity - lastEquity;
    const changePercent = lastEquity > 0 ? (change / lastEquity) * 100 : 0;
    
    return { change, changePercent };
  };

  const getBuyingPowerUtilization = () => {
    if (!accountData) return 0;
    
    const totalBuyingPower = parseFloat(accountData.buying_power || '0');
    const longMarketValue = parseFloat(accountData.long_market_value || '0');
    const cash = parseFloat(accountData.cash || '0');
    
    if (isNaN(totalBuyingPower) || isNaN(longMarketValue) || isNaN(cash)) {
      return 0;
    }
    
    const usedMargin = longMarketValue - cash;
    
    return totalBuyingPower > 0 ? Math.max(0, Math.min(100, (usedMargin / totalBuyingPower) * 100)) : 0;
  };

  const getMarginUtilization = () => {
    if (!accountData) return 0;
    
    const maintenanceMargin = parseFloat(accountData.maintenance_margin || '0');
    const equity = parseFloat(accountData.equity || '0');
    
    if (isNaN(maintenanceMargin) || isNaN(equity)) {
      return 0;
    }
    
    return equity > 0 ? (maintenanceMargin / equity) * 100 : 0;
  };

  const getAccountStatus = () => {
    if (!accountData) return { status: 'Unknown', color: 'var(--text-secondary)' };
    
    if (accountData.account_blocked) {
      return { status: 'Blocked', color: 'var(--error)' };
    }
    if (accountData.trading_blocked) {
      return { status: 'Trading Restricted', color: 'var(--warning)' };
    }
    if (accountData.trade_suspended_by_user) {
      return { status: 'User Suspended', color: 'var(--warning)' };
    }
    if (accountData.status === 'ACTIVE') {
      return { status: 'Active', color: 'var(--success)' };
    }
    
    return { status: accountData.status, color: 'var(--text-secondary)' };
  };

  const fetchBankingData = async () => {
    setBankingLoading(true);
    try {
      const [accountsData, transfersData] = await Promise.all([
        fundingService.getBankAccounts().catch(() => []),
        fundingService.getTransfers().catch(() => [])
      ]);
      setBankAccounts(accountsData);
      setRecentTransfers(transfersData.slice(0, 3)); // Show only recent 3 transfers
    } catch (err) {
      console.error('Error loading banking data:', err);
    } finally {
      setBankingLoading(false);
    }
  };

  const refreshData = () => {
    fetchAccountData();
    fetchBankingData();
  };

  const handleDepositSuccess = () => {
    fetchBankingData();
    fetchAccountData();
  };

  const handleBankAccountsUpdated = () => {
    fetchBankingData();
  };

  if (isLoading && !accountData) {
    return (
      <div className="accounts-panel">
        <div className="panel-loading">
          <div className="spinner" />
          <span>Loading account data...</span>
        </div>
      </div>
    );
  }

  if (error && !accountData) {
    return (
      <div className="accounts-panel">
        <div className="panel-error">
          <p>Failed to load account data</p>
          <button onClick={fetchAccountData} className="retry-button">
            Retry
          </button>
        </div>
      </div>
    );
  }

  if (!accountData) return null;

  const dayPerformance = getDayPerformance();
  const buyingPowerUtil = getBuyingPowerUtilization();
  const marginUtil = getMarginUtilization();
  const accountStatus = getAccountStatus();

  return (
    <div className="accounts-panel">
      <div className="accounts-content">
        {/* Header with refresh */}
        <div className="accounts-header">
          <div className="account-number">
            Account: {accountData.account_number}
          </div>
          <div className="refresh-section">
            <button onClick={refreshData} className="refresh-button" disabled={isLoading}>
              {isLoading ? '⟳' : '↻'}
            </button>
            <span className="last-update">
              {lastRefresh.toLocaleTimeString('en-US', { 
                hour: '2-digit', 
                minute: '2-digit',
                second: '2-digit'
              })}
            </span>
          </div>
        </div>

        {/* Tab Navigation */}
        <div className="accounts-tabs">
          <button
            className={`accounts-tab ${activeTab === 'overview' ? 'active' : ''}`}
            onClick={() => setActiveTab('overview')}
          >
            Overview
          </button>
          <button
            className={`accounts-tab ${activeTab === 'banking' ? 'active' : ''}`}
            onClick={() => setActiveTab('banking')}
          >
            Banking & Funding
          </button>
        </div>

        {/* Tab Content */}
        {activeTab === 'overview' && (
          <>
            {/* Account Status */}
            <div className="account-status">
              <div className="status-item">
                <span className="status-label">Status:</span>
                <span 
                  className="status-value"
                  style={{ color: accountStatus.color }}
                >
                  {accountStatus.status}
                </span>
              </div>
              <div className="status-item">
                {accountData.pattern_day_trader ? (
                  <>
                    <div className="pdt-indicator">
                      <span className="pdt-badge">PDT</span>
                    </div>
                    <div className="day-trades-info">
                      <span className="status-label">Day Trades:</span>
                      <span className="status-value">{accountData.daytrade_count}/∞</span>
                    </div>
                  </>
                ) : (
                  <div className="day-trades-info">
                    <span className="status-label">Day Trades Left:</span>
                    <span className={`status-value ${accountData.daytrade_count >= 3 ? 'warning' : ''}`}>
                      {Math.max(0, 3 - accountData.daytrade_count)}
                    </span>
                  </div>
                )}
              </div>
            </div>

        {/* Main Account Overview */}
        <div className="account-overview">
          <div className="overview-section">
            <h3>Account Value</h3>
            <div className="metric-group">
              <div className="main-metric">
                <span className="metric-label">Total Equity</span>
                <span className="metric-value large">
                  {formatCurrency(accountData.equity)}
                </span>
              </div>
              <div className="day-change">
                <span className="change-label">Today's Change</span>
                <div className={`change-value ${dayPerformance.change >= 0 ? 'positive' : 'negative'}`}>
                  <span className="change-amount">
                    {formatCurrency(dayPerformance.change)}
                  </span>
                  <span className="change-percent">
                    ({formatPercent(dayPerformance.changePercent)})
                  </span>
                </div>
              </div>
            </div>
          </div>

          <div className="overview-section">
            <h3>Buying Power</h3>
            <div className="metric-group">
              <div className="metric-row">
                <span className="metric-label">Available</span>
                <span className="metric-value">
                  {formatCurrency(accountData.buying_power)}
                </span>
              </div>
              {accountData.pattern_day_trader && (
                <div className="metric-row">
                  <span className="metric-label">Day Trading</span>
                  <span className="metric-value">
                    {formatCurrency(accountData.daytrading_buying_power)}
                  </span>
                </div>
              )}
              <div className="utilization-bar">
                <div className="bar-header">
                  <span className="bar-label">Utilization</span>
                  <span className="bar-value">{buyingPowerUtil.toFixed(1)}%</span>
                </div>
                <div className="progress-bar">
                  <div 
                    className="progress-fill buying-power"
                    style={{ width: `${Math.min(100, buyingPowerUtil)}%` }}
                  />
                </div>
              </div>
            </div>
          </div>

          <div className="overview-section">
            {parseFloat(accountData.multiplier) > 1 ? (
              <>
                <h3>Cash & Margin</h3>
                <div className="metric-group">
                  <div className="metric-row">
                    <span className="metric-label">Cash Available</span>
                    <span className="metric-value">
                      {formatCurrency(accountData.cash)}
                    </span>
                  </div>
                  <div className="metric-row">
                    <span className="metric-label">Margin Used</span>
                    <span className="metric-value">
                      {formatCurrency(accountData.initial_margin)}
                    </span>
                  </div>
                  <div className="metric-row">
                    <span className="metric-label">Maintenance Margin</span>
                    <span className="metric-value">
                      {formatCurrency(accountData.maintenance_margin)}
                    </span>
                  </div>
                  {parseFloat(accountData.maintenance_margin) > 0 && (
                    <div className="utilization-bar">
                      <div className="bar-header">
                        <span className="bar-label">Margin Risk</span>
                        <span className="bar-value">{marginUtil.toFixed(1)}%</span>
                      </div>
                      <div className="progress-bar">
                        <div 
                          className={`progress-fill margin ${marginUtil > 80 ? 'high-risk' : marginUtil > 60 ? 'medium-risk' : 'low-risk'}`}
                          style={{ width: `${Math.min(100, marginUtil)}%` }}
                        />
                      </div>
                    </div>
                  )}
                </div>
              </>
            ) : (
              <>
                <h3>Cash</h3>
                <div className="metric-group">
                  <div className="metric-row">
                    <span className="metric-label">Cash Available</span>
                    <span className="metric-value">
                      {formatCurrency(accountData.cash)}
                    </span>
                  </div>
                  <div className="metric-row">
                    <span className="metric-label">Cash Withdrawable</span>
                    <span className="metric-value">
                      {formatCurrency(accountData.cash_withdrawable)}
                    </span>
                  </div>
                </div>
              </>
            )}
          </div>

        </div>

            {/* Alerts/Warnings */}
            {(accountData.trading_blocked || accountData.account_blocked || accountData.daytrade_count >= 3) && (
              <div className="account-alerts">
                {accountData.account_blocked && (
                  <div className="alert error">
                    <span className="alert-icon">⚠</span>
                    Account is blocked - Contact support
                  </div>
                )}
                {accountData.trading_blocked && (
                  <div className="alert warning">
                    <span className="alert-icon">⚠</span>
                    Trading is currently restricted
                  </div>
                )}
                {!accountData.pattern_day_trader && accountData.daytrade_count >= 3 && (
                  <div className="alert warning">
                    <span className="alert-icon">⚠</span>
                    Day trade limit reached - Account may be restricted
                  </div>
                )}
              </div>
            )}
          </>
        )}

        {activeTab === 'banking' && (
          <>
            {/* Banking & Funding Content */}
        <div className="overview-section banking-section">
          <div className="banking-header">
            <h3>Banking & Funding</h3>
            <div className="banking-actions">
              <button 
                className="action-button deposit-button"
                onClick={() => setShowDepositModal(true)}
                disabled={bankAccounts.length === 0}
              >
                Deposit
              </button>
              <button 
                className="action-button manage-button"
                onClick={() => setShowBankModal(true)}
              >
                {bankAccounts.length === 0 ? 'Link Bank' : 'Manage'}
              </button>
            </div>
          </div>
          
          <div className="banking-content">
            <div className="banking-summary">
              <div className="metric-row">
                <span className="metric-label">Linked Accounts</span>
                <span className="metric-value">
                  {bankingLoading ? '...' : bankAccounts.length}
                </span>
              </div>
              {bankAccounts.length > 0 && (
                <div className="bank-account-summary">
                  {bankAccounts.slice(0, 2).map((account) => (
                    <div key={account.id} className="bank-summary-item">
                      <span className="bank-name">
                        {account.nickname || 'Bank Account'}
                      </span>
                      <span className={`bank-status ${account.status.toLowerCase()}`}>
                        ****{account.bankAccountNumber?.slice(-4) || ''}
                      </span>
                    </div>
                  ))}
                  {bankAccounts.length > 2 && (
                    <div className="bank-summary-more">
                      +{bankAccounts.length - 2} more
                    </div>
                  )}
                </div>
              )}
            </div>
            
            <div className="transfers-summary">
              <div className="transfers-header">
                <span className="transfers-label">Recent Transfers</span>
                {recentTransfers.length > 0 && (
                  <button 
                    className="view-all-button"
                    onClick={() => setShowTransferModal(true)}
                  >
                    View All
                  </button>
                )}
              </div>
              {bankingLoading ? (
                <div className="transfers-loading">Loading...</div>
              ) : recentTransfers.length === 0 ? (
                <div className="no-transfers">No recent transfers</div>
              ) : (
                <div className="recent-transfers">
                  {recentTransfers.map((transfer) => (
                    <div key={transfer.id} className="transfer-summary-item">
                      <div className="transfer-info">
                        <span className="transfer-type">
                          {transfer.direction === 'INCOMING' ? 'Deposit' : 'Withdrawal'}
                        </span>
                        <span className="transfer-amount">
                          ${parseFloat(transfer.amount).toFixed(2)}
                        </span>
                      </div>
                      <span className={`transfer-status ${transfer.status.toLowerCase()}`}>
                        {transfer.status}
                      </span>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        </div>
          </>
        )}

        {config.linkGroup && (
          <div className="link-indicator">
            Linked to: {config.linkGroup}
          </div>
        )}
      </div>

      {/* Modals */}
      <DepositFundsModal
        isOpen={showDepositModal}
        onClose={() => setShowDepositModal(false)}
        bankAccounts={bankAccounts}
        onDepositSuccess={handleDepositSuccess}
      />
      
      <BankManagementModal
        isOpen={showBankModal}
        onClose={() => setShowBankModal(false)}
        onBankAccountsUpdated={handleBankAccountsUpdated}
      />
      
      <TransferHistoryModal
        isOpen={showTransferModal}
        onClose={() => setShowTransferModal(false)}
      />
    </div>
  );
};

AccountsPanel.displayName = 'Accounts';

export default AccountsPanel;