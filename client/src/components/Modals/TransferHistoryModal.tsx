import React, { useState, useEffect } from 'react';
import { fundingService } from '../../services/fundingService';
import type { Transfer } from '../../services/fundingService';
import styles from './TransferHistoryModal.module.css';

interface TransferHistoryModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const TransferHistoryModal: React.FC<TransferHistoryModalProps> = ({
  isOpen,
  onClose,
}) => {
  const [transfers, setTransfers] = useState<Transfer[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [typeFilter, setTypeFilter] = useState<string>('all');

  useEffect(() => {
    if (isOpen) {
      loadTransfers();
    }
  }, [isOpen]);

  const loadTransfers = async () => {
    try {
      setIsLoading(true);
      setError(null);
      const transfersData = await fundingService.getTransfers();
      setTransfers(transfersData);
    } catch (err) {
      console.error('Error loading transfers:', err);
      setError('Failed to load transfer history');
    } finally {
      setIsLoading(false);
    }
  };

  const filteredTransfers = transfers.filter(transfer => {
    const statusMatch = statusFilter === 'all' || transfer.status.toLowerCase() === statusFilter;
    const typeMatch = typeFilter === 'all' || transfer.direction.toLowerCase() === typeFilter;
    return statusMatch && typeMatch;
  });

  const handleClose = () => {
    setError(null);
    setStatusFilter('all');
    setTypeFilter('all');
    onClose();
  };

  const formatAmount = (amount: string) => {
    return parseFloat(amount).toLocaleString('en-US', { 
      minimumFractionDigits: 2,
      maximumFractionDigits: 2 
    });
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  const getStatusColor = (status: string) => {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'settled':
        return 'success';
      case 'pending':
      case 'processing':
        return 'pending';
      case 'failed':
      case 'cancelled':
        return 'error';
      default:
        return 'default';
    }
  };

  if (!isOpen) return null;

  return (
    <div className={styles.overlay} onClick={handleClose}>
      <div className={styles.modal} onClick={(e) => e.stopPropagation()}>
        <div className={styles.header}>
          <h2>Transfer History</h2>
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

          <div className={styles.filters}>
            <div className={styles.filterGroup}>
              <label htmlFor="statusFilter">Status</label>
              <select
                id="statusFilter"
                value={statusFilter}
                onChange={(e) => setStatusFilter(e.target.value)}
                className={styles.filterSelect}
              >
                <option value="all">All Statuses</option>
                <option value="pending">Pending</option>
                <option value="processing">Processing</option>
                <option value="completed">Completed</option>
                <option value="settled">Settled</option>
                <option value="failed">Failed</option>
                <option value="cancelled">Cancelled</option>
              </select>
            </div>
            <div className={styles.filterGroup}>
              <label htmlFor="typeFilter">Type</label>
              <select
                id="typeFilter"
                value={typeFilter}
                onChange={(e) => setTypeFilter(e.target.value)}
                className={styles.filterSelect}
              >
                <option value="all">All Types</option>
                <option value="incoming">Deposits</option>
                <option value="outgoing">Withdrawals</option>
              </select>
            </div>
          </div>

          {isLoading ? (
            <div className={styles.loading}>
              <div className={styles.loadingSpinner}></div>
              Loading transfer history...
            </div>
          ) : filteredTransfers.length === 0 ? (
            <div className={styles.emptyState}>
              <div className={styles.emptyIcon}>
                <svg width="48" height="48" viewBox="0 0 24 24" fill="none">
                  <path d="M12 5V19" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                  <path d="M5 12L12 19L19 12" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                </svg>
              </div>
              <p>No transfers found</p>
              <p className={styles.emptySubtext}>
                {transfers.length === 0 
                  ? "Your transfer history will appear here"
                  : "No transfers match your current filters"
                }
              </p>
            </div>
          ) : (
            <div className={styles.transferList}>
              {filteredTransfers.map((transfer) => (
                <div key={transfer.id} className={styles.transferItem}>
                  <div className={styles.transferIcon}>
                    {transfer.direction === 'INCOMING' ? (
                      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" className={styles.depositIcon}>
                        <path d="M12 5V19" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                        <path d="M5 12L12 19L19 12" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                      </svg>
                    ) : (
                      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" className={styles.withdrawalIcon}>
                        <path d="M12 19V5" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                        <path d="M5 12L12 5L19 12" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                      </svg>
                    )}
                  </div>
                  <div className={styles.transferDetails}>
                    <div className={styles.transferHeader}>
                      <span className={styles.transferType}>
                        {transfer.direction === 'INCOMING' ? 'Deposit' : 'Withdrawal'}
                      </span>
                      <span className={`${styles.transferStatus} ${styles[getStatusColor(transfer.status)]}`}>
                        {transfer.status}
                      </span>
                    </div>
                    <div className={styles.transferAmount}>
                      ${formatAmount(transfer.amount)}
                    </div>
                    <div className={styles.transferDate}>
                      {formatDate(transfer.createdAt)}
                    </div>
                    {transfer.reason && (
                      <div className={styles.transferReason}>
                        {transfer.reason}
                      </div>
                    )}
                    {transfer.expiresAt && new Date(transfer.expiresAt) > new Date() && (
                      <div className={styles.transferExpiry}>
                        Expires: {formatDate(transfer.expiresAt)}
                      </div>
                    )}
                  </div>
                  <div className={styles.transferId}>
                    ID: {transfer.id.slice(-8)}
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        <div className={styles.footer}>
          <div className={styles.summary}>
            {!isLoading && (
              <span className={styles.resultCount}>
                {filteredTransfers.length} of {transfers.length} transfers
              </span>
            )}
          </div>
          <button onClick={handleClose} className={styles.closeFooterButton}>
            Close
          </button>
        </div>
      </div>
    </div>
  );
};