import React, { useState } from 'react';

interface DocumentUploadScreenProps {
  onNext: (data: DocumentData) => void;
  data?: DocumentData;
}

interface DocumentData {
  idType: 'drivers_license' | 'passport';
  idFront: File | null;
  idBack?: File | null;
}

const DocumentUploadScreen: React.FC<DocumentUploadScreenProps> = ({ onNext, data }) => {
  const [formData] = useState<DocumentData>({
    idType: data?.idType || 'drivers_license',
    idFront: data?.idFront || null,
    idBack: data?.idBack || null
  });
  
  // TODO: Implement form handling
  // const [formData, setFormData] = useState<DocumentData>(...)
  
  const handleSubmit = () => {
    // TODO: Add validation
    onNext(formData);
  };
  
  return (
    <div className="screen-content">
      <h1>Document Upload</h1>
      <p>Please upload a photo of your government-issued ID.</p>
      
      {/* TODO: Add file upload interface */}
      
      <div className="onboarding-screen-footer">
        <button className="btn-primary" onClick={handleSubmit}>
          Continue
        </button>
      </div>
    </div>
  );
};

export default DocumentUploadScreen;