import React from 'react';
import { useNavigate } from 'react-router-dom';
import type { KycStatus } from '../../types';
import styles from './KYCStatusCard.module.css';

interface KYCStatusCardProps {
  kycStatus: KycStatus;
  completionPercentage: number;
  onDismiss?: () => void;
}

const KYCStatusCard: React.FC<KYCStatusCardProps> = ({
  kycStatus,
  completionPercentage,
  onDismiss
}) => {
  const navigate = useNavigate();

  if (kycStatus === 'Approved') {
    return null;
  }

  const getStatusMessage = () => {
    switch (kycStatus) {
      case 'NotStarted':
        return {
          title: 'Complete Your Account Setup',
          subtitle: 'Verify your identity to unlock all trading features',
          buttonText: 'Start Verification',
          estimatedTime: 'About 10 minutes'
        };
      case 'InProgress':
        return {
          title: 'Complete Your Account Setup',
          subtitle: `You're ${completionPercentage}% done with your verification`,
          buttonText: 'Resume Verification',
          estimatedTime: `About ${Math.ceil((100 - completionPercentage) / 10)} minutes remaining`
        };
      case 'UnderReview':
        return {
          title: 'Verification Under Review',
          subtitle: 'We\'re reviewing your information. This usually takes 1-2 business days.',
          buttonText: 'View Status',
          estimatedTime: 'Check back soon'
        };
      case 'Rejected':
        return {
          title: 'Verification Needs Attention',
          subtitle: 'There was an issue with your verification. Please review and resubmit.',
          buttonText: 'Review & Resubmit',
          estimatedTime: 'About 10 minutes'
        };
      default:
        return null;
    }
  };

  const statusInfo = getStatusMessage();
  if (!statusInfo) return null;

  const handleAction = () => {
    navigate('/register', { state: { resumeKyc: true } });
  };

  return (
    <div className={styles.kycCard}>
      <div className={styles.content}>
        <div className={styles.iconWrapper}>
          <svg className={styles.icon} viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
            <path d="M9 11H7a2 2 0 0 0-2 2v6a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2v-6a2 2 0 0 0-2-2h-2" stroke="currentColor" strokeWidth="2" strokeLinecap="round"/>
            <path d="M12 17v-6" stroke="currentColor" strokeWidth="2" strokeLinecap="round"/>
            <path d="M9 11V7a3 3 0 1 1 6 0v4" stroke="currentColor" strokeWidth="2" strokeLinecap="round"/>
          </svg>
        </div>
        
        <div className={styles.textContent}>
          <h3 className={styles.title}>{statusInfo.title}</h3>
          <p className={styles.subtitle}>{statusInfo.subtitle}</p>
          
          {kycStatus === 'InProgress' && (
            <div className={styles.progressWrapper}>
              <div className={styles.progressBar}>
                <div 
                  className={styles.progressFill} 
                  style={{ width: `${completionPercentage}%` }}
                />
              </div>
              <span className={styles.progressText}>{completionPercentage}% Complete</span>
            </div>
          )}
          
          <p className={styles.estimatedTime}>
            <svg className={styles.clockIcon} viewBox="0 0 16 16" fill="none">
              <circle cx="8" cy="8" r="7" stroke="currentColor" strokeWidth="1.5"/>
              <path d="M8 4v4l2 2" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round"/>
            </svg>
            {statusInfo.estimatedTime}
          </p>
        </div>
        
        <div className={styles.actions}>
          <button
            onClick={handleAction}
            className={styles.primaryButton}
          >
            {statusInfo.buttonText}
          </button>
          
          {kycStatus !== 'UnderReview' && onDismiss && (
            <button
              onClick={onDismiss}
              className={styles.dismissButton}
              aria-label="Dismiss"
            >
              <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                <path d="M18 6L6 18M6 6l12 12" stroke="currentColor" strokeWidth="2" strokeLinecap="round"/>
              </svg>
            </button>
          )}
        </div>
      </div>
      
      {kycStatus !== 'UnderReview' && (
        <div className={styles.benefits}>
          <p className={styles.benefitsTitle}>Unlock these features:</p>
          <ul className={styles.benefitsList}>
            <li>Real-time trading on stocks, options & crypto</li>
            <li>Instant deposits and withdrawals</li>
            <li>Advanced trading tools and analytics</li>
          </ul>
        </div>
      )}
    </div>
  );
};

export default KYCStatusCard;