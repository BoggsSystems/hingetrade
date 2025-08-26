import React, { useEffect, useRef } from 'react';
import { CSSTransition } from 'react-transition-group';
import './LegalDocumentModal.css';

interface LegalDocumentModalProps {
  isOpen: boolean;
  onClose: () => void;
  documentType: 'terms' | 'privacy';
  title: string;
  children: React.ReactNode;
}

const LegalDocumentModal: React.FC<LegalDocumentModalProps> = ({
  isOpen,
  onClose,
  title,
  children
}) => {
  const modalRef = useRef<HTMLDivElement>(null);
  
  useEffect(() => {
    const handleEscape = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        onClose();
      }
    };

    if (isOpen) {
      document.addEventListener('keydown', handleEscape);
      document.body.style.overflow = 'hidden';
    }

    return () => {
      document.removeEventListener('keydown', handleEscape);
      document.body.style.overflow = 'unset';
    };
  }, [isOpen, onClose]);

  const handleOverlayClick = (event: React.MouseEvent<HTMLDivElement>) => {
    if (event.target === event.currentTarget) {
      onClose();
    }
  };

  return (
    <CSSTransition
      in={isOpen}
      timeout={300}
      classNames="legal-modal"
      unmountOnExit
      nodeRef={modalRef}
    >
      <div className="legal-modal-overlay" onClick={handleOverlayClick} ref={modalRef}>
        <div className="legal-modal">
          <div className="legal-modal-header">
            <h2>{title}</h2>
            <button 
              className="legal-modal-close" 
              onClick={onClose}
              aria-label="Close"
            >
              ×
            </button>
          </div>
          
          <div className="legal-modal-content">
            {children}
          </div>
          
          <div className="legal-modal-footer">
            <button className="btn-primary" onClick={onClose}>
              I Understand
            </button>
          </div>
        </div>
      </div>
    </CSSTransition>
  );
};

export default LegalDocumentModal;