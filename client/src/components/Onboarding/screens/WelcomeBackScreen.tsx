import React from 'react';
import type { KYCProgress } from '../../../utils/kycHelpers';
import { getStepDisplayName, isStepComplete, getEstimatedTimeRemaining } from '../../../utils/kycHelpers';
import '../OnboardingModal.css';

interface WelcomeBackScreenProps {
  onContinue: () => void;
  onStartOver?: () => void;
  progress: KYCProgress;
  completionPercentage: number;
  username?: string;
}

const WelcomeBackScreen: React.FC<WelcomeBackScreenProps> = ({
  onContinue,
  onStartOver,
  progress,
  completionPercentage,
  username
}) => {
  const steps = [
    { key: 'accountCredentials', required: true },
    { key: 'personalInfo', required: true },
    { key: 'address', required: true },
    { key: 'identity', required: true },
    { key: 'documents', required: true },
    { key: 'financialProfile', required: true },
    { key: 'agreements', required: true },
    { key: 'bankAccount', required: false }
  ];

  const estimatedTime = getEstimatedTimeRemaining(completionPercentage);

  return (
    <div className="onboarding-screen welcome-back-screen">
      <div className="screen-header">
        <h2>Welcome back{username ? `, ${username}` : ''}!</h2>
        <p>You're {completionPercentage}% done with your account setup</p>
      </div>

      <div className="progress-overview">
        <div className="progress-ring">
          <svg viewBox="0 0 100 100">
            <circle
              cx="50"
              cy="50"
              r="40"
              fill="none"
              stroke="#e2e8f0"
              strokeWidth="8"
            />
            <circle
              cx="50"
              cy="50"
              r="40"
              fill="none"
              stroke="#4f46e5"
              strokeWidth="8"
              strokeDasharray={`${2 * Math.PI * 40}`}
              strokeDashoffset={`${2 * Math.PI * 40 * (1 - completionPercentage / 100)}`}
              transform="rotate(-90 50 50)"
              style={{ transition: 'stroke-dashoffset 0.5s ease' }}
            />
          </svg>
          <div className="progress-text">
            <span className="percentage">{completionPercentage}%</span>
            <span className="label">Complete</span>
          </div>
        </div>

        <div className="steps-list">
          <h3>Your Progress</h3>
          {steps.map((step) => {
            const isComplete = isStepComplete(step.key, progress);
            return (
              <div key={step.key} className={`step-item ${isComplete ? 'complete' : 'pending'}`}>
                <div className="step-icon">
                  {isComplete ? (
                    <svg viewBox="0 0 20 20" fill="currentColor">
                      <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                    </svg>
                  ) : (
                    <div className="step-circle" />
                  )}
                </div>
                <span className="step-name">{getStepDisplayName(step.key)}</span>
                {!step.required && <span className="optional">(Optional)</span>}
              </div>
            );
          })}
        </div>
      </div>

      <div className="time-estimate">
        <svg className="clock-icon" viewBox="0 0 20 20" fill="currentColor">
          <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-12a1 1 0 10-2 0v4a1 1 0 00.293.707l3 3a1 1 0 001.414-1.414L11 9.586V6z" clipRule="evenodd" />
        </svg>
        <span>About {estimatedTime} {estimatedTime === 1 ? 'minute' : 'minutes'} remaining</span>
      </div>

      <div className="screen-actions">
        <button onClick={onContinue} className="btn-primary">
          Continue Setup
        </button>
        {onStartOver && (
          <button onClick={onStartOver} className="btn-text">
            Start Over
          </button>
        )}
      </div>
    </div>
  );
};

export default WelcomeBackScreen;