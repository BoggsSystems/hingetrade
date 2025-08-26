import React, { useState, useRef, useEffect } from 'react';

interface DocumentUploadScreenProps {
  onNext: (data: DocumentData) => void;
  data?: DocumentData;
}

export interface DocumentData {
  idType: 'drivers_license' | 'passport';
  idFront: File | null;
  idBack?: File | null;
  idFrontPreview?: string;
  idBackPreview?: string;
}

const DocumentUploadScreen: React.FC<DocumentUploadScreenProps> = ({ onNext, data }) => {
  const [formData, setFormData] = useState<DocumentData>({
    idType: data?.idType || 'drivers_license',
    idFront: data?.idFront || null,
    idBack: data?.idBack || null,
    idFrontPreview: data?.idFrontPreview,
    idBackPreview: data?.idBackPreview
  });
  
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [uploading, setUploading] = useState(false);
  
  const frontInputRef = useRef<HTMLInputElement>(null);
  const backInputRef = useRef<HTMLInputElement>(null);
  
  // Debug - log when component mounts and refs change
  useEffect(() => {
    console.log('DocumentUploadScreen mounted/updated');
    console.log('Front input ref current:', frontInputRef.current);
    console.log('Back input ref current:', backInputRef.current);
  });
  
  const MAX_FILE_SIZE = 10 * 1024 * 1024; // 10MB
  const ALLOWED_TYPES = ['image/jpeg', 'image/jpg', 'image/png', 'image/pdf', 'application/pdf'];
  
  const handleIdTypeChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    const newType = e.target.value as 'drivers_license' | 'passport';
    setFormData(prev => ({
      ...prev,
      idType: newType,
      idFront: null,
      idBack: null,
      idFrontPreview: undefined,
      idBackPreview: undefined
    }));
    setErrors({});
    
    // Reset file inputs
    if (frontInputRef.current) frontInputRef.current.value = '';
    if (backInputRef.current) backInputRef.current.value = '';
  };
  
  const validateFile = (file: File): string | null => {
    if (!ALLOWED_TYPES.includes(file.type)) {
      return 'File must be JPG, PNG, or PDF';
    }
    if (file.size > MAX_FILE_SIZE) {
      return 'File size must be less than 10MB';
    }
    return null;
  };
  
  const readFileAsDataUrl = (file: File): Promise<string> => {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = (e) => resolve(e.target?.result as string);
      reader.onerror = reject;
      reader.readAsDataURL(file);
    });
  };
  
  const handleFileChange = async (e: React.ChangeEvent<HTMLInputElement>, side: 'front' | 'back') => {
    console.log(`${side} file input changed:`, e.target.files);
    const file = e.target.files?.[0];
    if (!file) return;
    
    const error = validateFile(file);
    if (error) {
      setErrors(prev => ({ ...prev, [`id${side.charAt(0).toUpperCase() + side.slice(1)}`]: error }));
      e.target.value = ''; // Reset input
      return;
    }
    
    setUploading(true);
    setErrors(prev => ({ ...prev, [`id${side.charAt(0).toUpperCase() + side.slice(1)}`]: '' }));
    
    try {
      const preview = file.type.includes('pdf') ? null : await readFileAsDataUrl(file);
      
      if (side === 'front') {
        setFormData(prev => ({
          ...prev,
          idFront: file,
          idFrontPreview: preview || undefined
        }));
      } else {
        setFormData(prev => ({
          ...prev,
          idBack: file,
          idBackPreview: preview || undefined
        }));
      }
    } catch (error) {
      console.error('Error reading file:', error);
      setErrors(prev => ({ ...prev, [`id${side.charAt(0).toUpperCase() + side.slice(1)}`]: 'Error reading file' }));
    } finally {
      setUploading(false);
    }
  };
  
  const removeFile = (side: 'front' | 'back') => {
    if (side === 'front') {
      setFormData(prev => ({ ...prev, idFront: null, idFrontPreview: undefined }));
      if (frontInputRef.current) frontInputRef.current.value = '';
    } else {
      setFormData(prev => ({ ...prev, idBack: null, idBackPreview: undefined }));
      if (backInputRef.current) backInputRef.current.value = '';
    }
    setErrors(prev => ({ ...prev, [`id${side.charAt(0).toUpperCase() + side.slice(1)}`]: '' }));
  };
  
  const triggerFileInput = (side: 'front' | 'back') => {
    console.log(`Triggering ${side} file input`);
    const inputRef = side === 'front' ? frontInputRef : backInputRef;
    
    if (inputRef.current) {
      console.log(`${side} input ref exists, clicking...`);
      // Use setTimeout to break out of the current event loop
      setTimeout(() => {
        inputRef.current?.click();
      }, 0);
    } else {
      console.error(`${side} input ref is null`);
    }
  };
  
  const validateForm = (): boolean => {
    const newErrors: Record<string, string> = {};
    
    if (!formData.idFront) {
      newErrors.idFront = 'Front of ID is required';
    }
    
    if (formData.idType === 'drivers_license' && !formData.idBack) {
      newErrors.idBack = 'Back of driver\'s license is required';
    }
    
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };
  
  const handleSubmit = () => {
    if (validateForm()) {
      onNext(formData);
    }
  };
  
  return (
    <div className="screen-content">
      <div className="screen-header">
        <h2>Identity Verification Documents</h2>
        <p>Upload clear photos of your government-issued ID. Make sure all text is readable and the entire document is visible.</p>
      </div>
      
      <div className="form-group">
        <label>Document Type</label>
        <select 
          value={formData.idType}
          onChange={handleIdTypeChange}
          className="form-control"
        >
          <option value="drivers_license">Driver's License</option>
          <option value="passport">Passport</option>
        </select>
      </div>
      
      <div className="form-row" style={{ gap: '24px', marginTop: '24px' }}>
        <div className="form-group" style={{ flex: 1 }}>
          <label>
            {formData.idType === 'drivers_license' ? 'Front of License' : 'Passport Photo Page'}
          </label>
          
          {!formData.idFront ? (
            <div className="file-upload-area">
              <input
                ref={frontInputRef}
                type="file"
                accept="image/jpeg,image/jpg,image/png,application/pdf"
                onChange={(e) => handleFileChange(e, 'front')}
                style={{ 
                  position: 'absolute',
                  left: '-9999px',
                  visibility: 'hidden',
                  opacity: 0
                }}
              />
              <div 
                className="file-upload-label"
                onClick={(e) => {
                  e.stopPropagation();
                  triggerFileInput('front');
                }}
                onMouseDown={(e) => e.stopPropagation()}
                style={{ cursor: 'pointer', position: 'relative', zIndex: 10 }}
              >
                <div className="upload-icon">📷</div>
                <p>Click to upload or drag and drop</p>
                <p className="upload-hint">JPG, PNG or PDF (max 10MB)</p>
              </div>
            </div>
          ) : (
            <div className="file-preview">
              {formData.idFrontPreview ? (
                <img src={formData.idFrontPreview} alt="ID Front" />
              ) : (
                <div className="pdf-preview">
                  <div className="pdf-icon">📄</div>
                  <p>{formData.idFront.name}</p>
                </div>
              )}
              <button 
                type="button"
                className="remove-file"
                onClick={() => removeFile('front')}
              >
                Remove
              </button>
            </div>
          )}
          {errors.idFront && <span className="error">{errors.idFront}</span>}
        </div>
        
        {formData.idType === 'drivers_license' && (
          <div className="form-group" style={{ flex: 1 }}>
            <label>Back of License</label>
            
            {!formData.idBack ? (
              <div className="file-upload-area">
                <input
                  ref={backInputRef}
                  type="file"
                  accept="image/jpeg,image/jpg,image/png,application/pdf"
                  onChange={(e) => handleFileChange(e, 'back')}
                  style={{ 
                    position: 'absolute',
                    left: '-9999px',
                    visibility: 'hidden',
                    opacity: 0
                  }}
                />
                <div 
                  className="file-upload-label"
                  onClick={(e) => {
                    e.stopPropagation();
                    triggerFileInput('back');
                  }}
                  onMouseDown={(e) => e.stopPropagation()}
                  style={{ cursor: 'pointer', position: 'relative', zIndex: 10 }}
                >
                  <div className="upload-icon">📷</div>
                  <p>Click to upload or drag and drop</p>
                  <p className="upload-hint">JPG, PNG or PDF (max 10MB)</p>
                </div>
              </div>
            ) : (
              <div className="file-preview">
                {formData.idBackPreview ? (
                  <img src={formData.idBackPreview} alt="ID Back" />
                ) : (
                  <div className="pdf-preview">
                    <div className="pdf-icon">📄</div>
                    <p>{formData.idBack.name}</p>
                  </div>
                )}
                <button 
                  type="button"
                  className="remove-file"
                  onClick={() => removeFile('back')}
                >
                  Remove
                </button>
              </div>
            )}
            {errors.idBack && <span className="error">{errors.idBack}</span>}
          </div>
        )}
      </div>
      
      <div className="info-box" style={{ marginTop: '24px' }}>
        <h4>📋 Document Requirements:</h4>
        <ul>
          <li>Must be valid and not expired</li>
          <li>Full document must be visible</li>
          <li>Text must be clear and readable</li>
          <li>No glare or shadows obscuring information</li>
          <li>Color photos preferred (not black & white)</li>
        </ul>
      </div>
      
      <div className="screen-actions">
        <button 
          className="btn-primary" 
          onClick={handleSubmit}
          disabled={uploading}
        >
          {uploading ? 'Processing...' : 'Continue'}
        </button>
      </div>
    </div>
  );
};

export default DocumentUploadScreen;