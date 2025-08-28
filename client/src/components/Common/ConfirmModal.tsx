import React from 'react';
import ReactDOM from 'react-dom';
import './ConfirmModal.css';

interface ConfirmModalProps {
  isOpen: boolean;
  title?: string;
  message: string;
  confirmText?: string;
  cancelText?: string;
  onConfirm: () => void;
  onCancel: () => void;
  variant?: 'danger' | 'warning' | 'info';
}

const ConfirmModal: React.FC<ConfirmModalProps> = ({
  isOpen,
  title = 'Confirm Action',
  message,
  confirmText = 'OK',
  cancelText = 'Cancel',
  onConfirm,
  onCancel,
  variant = 'warning'
}) => {
  if (!isOpen) return null;

  const handleBackdropClick = (e: React.MouseEvent) => {
    if (e.target === e.currentTarget) {
      onCancel();
    }
  };

  const modalContent = (
    <div className="confirm-modal-backdrop" onClick={handleBackdropClick}>
      <div className={`confirm-modal ${variant}`}>
        <div className="confirm-modal-header">
          <h3>{title}</h3>
        </div>
        <div className="confirm-modal-body">
          <p>{message}</p>
        </div>
        <div className="confirm-modal-footer">
          <button 
            className="confirm-modal-btn confirm-modal-btn-cancel" 
            onClick={onCancel}
          >
            {cancelText}
          </button>
          <button 
            className={`confirm-modal-btn confirm-modal-btn-${variant}`}
            onClick={onConfirm}
          >
            {confirmText}
          </button>
        </div>
      </div>
    </div>
  );

  // Use portal to render modal at document body level
  return ReactDOM.createPortal(
    modalContent,
    document.body
  );
};

export default ConfirmModal;