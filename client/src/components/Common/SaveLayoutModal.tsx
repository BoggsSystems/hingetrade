import React, { useState } from 'react';
import ReactDOM from 'react-dom';
import './SaveLayoutModal.css';

interface SaveLayoutModalProps {
  isOpen: boolean;
  title?: string;
  placeholder?: string;
  confirmText?: string;
  cancelText?: string;
  onConfirm: (value: string) => void;
  onCancel: () => void;
}

const SaveLayoutModal: React.FC<SaveLayoutModalProps> = ({
  isOpen,
  title = 'Save layout as:',
  placeholder = 'Enter layout name',
  confirmText = 'OK',
  cancelText = 'Cancel',
  onConfirm,
  onCancel
}) => {
  const [value, setValue] = useState('');

  if (!isOpen) return null;

  const handleBackdropClick = (e: React.MouseEvent) => {
    if (e.target === e.currentTarget) {
      onCancel();
    }
  };

  const handleConfirm = () => {
    if (value.trim()) {
      onConfirm(value.trim());
      setValue('');
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter') {
      handleConfirm();
    } else if (e.key === 'Escape') {
      onCancel();
    }
  };

  const modalContent = (
    <div className="save-layout-modal-backdrop" onClick={handleBackdropClick}>
      <div className="save-layout-modal">
        <div className="save-layout-modal-header">
          <h3>{title}</h3>
        </div>
        <div className="save-layout-modal-body">
          <input
            type="text"
            className="save-layout-input"
            placeholder={placeholder}
            value={value}
            onChange={(e) => setValue(e.target.value)}
            onKeyDown={handleKeyDown}
            autoFocus
          />
        </div>
        <div className="save-layout-modal-footer">
          <button 
            className="save-layout-btn save-layout-btn-cancel" 
            onClick={onCancel}
          >
            {cancelText}
          </button>
          <button 
            className="save-layout-btn save-layout-btn-confirm"
            onClick={handleConfirm}
            disabled={!value.trim()}
          >
            {confirmText}
          </button>
        </div>
      </div>
    </div>
  );

  return ReactDOM.createPortal(
    modalContent,
    document.body
  );
};

export default SaveLayoutModal;