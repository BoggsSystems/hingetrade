import React, { useState } from 'react';

interface AddressScreenProps {
  onNext: (data: AddressData) => void;
  data?: AddressData;
}

interface AddressData {
  streetAddress: string;
  streetAddress2?: string;
  city: string;
  state: string;
  zipCode: string;
  country: string;
  isMailingSame: boolean;
  mailingAddress?: {
    streetAddress: string;
    streetAddress2?: string;
    city: string;
    state: string;
    zipCode: string;
    country: string;
  };
}

const US_STATES = [
  { code: 'AL', name: 'Alabama' },
  { code: 'AK', name: 'Alaska' },
  { code: 'AZ', name: 'Arizona' },
  { code: 'AR', name: 'Arkansas' },
  { code: 'CA', name: 'California' },
  { code: 'CO', name: 'Colorado' },
  { code: 'CT', name: 'Connecticut' },
  { code: 'DE', name: 'Delaware' },
  { code: 'FL', name: 'Florida' },
  { code: 'GA', name: 'Georgia' },
  { code: 'HI', name: 'Hawaii' },
  { code: 'ID', name: 'Idaho' },
  { code: 'IL', name: 'Illinois' },
  { code: 'IN', name: 'Indiana' },
  { code: 'IA', name: 'Iowa' },
  { code: 'KS', name: 'Kansas' },
  { code: 'KY', name: 'Kentucky' },
  { code: 'LA', name: 'Louisiana' },
  { code: 'ME', name: 'Maine' },
  { code: 'MD', name: 'Maryland' },
  { code: 'MA', name: 'Massachusetts' },
  { code: 'MI', name: 'Michigan' },
  { code: 'MN', name: 'Minnesota' },
  { code: 'MS', name: 'Mississippi' },
  { code: 'MO', name: 'Missouri' },
  { code: 'MT', name: 'Montana' },
  { code: 'NE', name: 'Nebraska' },
  { code: 'NV', name: 'Nevada' },
  { code: 'NH', name: 'New Hampshire' },
  { code: 'NJ', name: 'New Jersey' },
  { code: 'NM', name: 'New Mexico' },
  { code: 'NY', name: 'New York' },
  { code: 'NC', name: 'North Carolina' },
  { code: 'ND', name: 'North Dakota' },
  { code: 'OH', name: 'Ohio' },
  { code: 'OK', name: 'Oklahoma' },
  { code: 'OR', name: 'Oregon' },
  { code: 'PA', name: 'Pennsylvania' },
  { code: 'RI', name: 'Rhode Island' },
  { code: 'SC', name: 'South Carolina' },
  { code: 'SD', name: 'South Dakota' },
  { code: 'TN', name: 'Tennessee' },
  { code: 'TX', name: 'Texas' },
  { code: 'UT', name: 'Utah' },
  { code: 'VT', name: 'Vermont' },
  { code: 'VA', name: 'Virginia' },
  { code: 'WA', name: 'Washington' },
  { code: 'WV', name: 'West Virginia' },
  { code: 'WI', name: 'Wisconsin' },
  { code: 'WY', name: 'Wyoming' }
];

const AddressScreen: React.FC<AddressScreenProps> = ({ onNext, data }) => {
  const [formData, setFormData] = useState<AddressData>({
    streetAddress: data?.streetAddress || '',
    streetAddress2: data?.streetAddress2 || '',
    city: data?.city || '',
    state: data?.state || '',
    zipCode: data?.zipCode || '',
    country: data?.country || 'USA',
    isMailingSame: data?.isMailingSame !== false,
    mailingAddress: data?.mailingAddress
  });
  
  const [errors, setErrors] = useState<Record<string, string>>({});
  
  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    const { name, value, type } = e.target;
    
    if (type === 'checkbox') {
      const checked = (e.target as HTMLInputElement).checked;
      setFormData(prev => ({ ...prev, [name]: checked }));
    } else if (name.startsWith('mailing.')) {
      const field = name.replace('mailing.', '');
      setFormData(prev => ({
        ...prev,
        mailingAddress: {
          ...prev.mailingAddress,
          [field]: value
        } as any
      }));
    } else {
      setFormData(prev => ({ ...prev, [name]: value }));
    }
    
    // Clear error
    if (errors[name]) {
      setErrors(prev => ({ ...prev, [name]: '' }));
    }
  };
  
  const validateForm = () => {
    const newErrors: Record<string, string> = {};
    
    // Residential address validation
    if (!formData.streetAddress.trim()) {
      newErrors.streetAddress = 'Street address is required';
    }
    if (!formData.city.trim()) {
      newErrors.city = 'City is required';
    }
    if (!formData.state) {
      newErrors.state = 'State is required';
    }
    if (!formData.zipCode.trim()) {
      newErrors.zipCode = 'ZIP code is required';
    } else if (!/^\d{5}(-\d{4})?$/.test(formData.zipCode)) {
      newErrors.zipCode = 'Invalid ZIP code format';
    }
    
    // Mailing address validation if different
    if (!formData.isMailingSame && formData.mailingAddress) {
      if (!formData.mailingAddress.streetAddress?.trim()) {
        newErrors['mailing.streetAddress'] = 'Mailing street address is required';
      }
      if (!formData.mailingAddress.city?.trim()) {
        newErrors['mailing.city'] = 'Mailing city is required';
      }
      if (!formData.mailingAddress.state) {
        newErrors['mailing.state'] = 'Mailing state is required';
      }
      if (!formData.mailingAddress.zipCode?.trim()) {
        newErrors['mailing.zipCode'] = 'Mailing ZIP code is required';
      }
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
      <h1>Address Information</h1>
      <p>Please provide your residential address.</p>
      
      <h2>Residential Address</h2>
      
      <div className="form-group">
        <label htmlFor="streetAddress">Street Address</label>
        <input
          type="text"
          id="streetAddress"
          name="streetAddress"
          value={formData.streetAddress}
          onChange={handleChange}
          placeholder="123 Main Street"
        />
        {errors.streetAddress && <div className="error-message">{errors.streetAddress}</div>}
      </div>
      
      <div className="form-group">
        <label htmlFor="streetAddress2">Apartment, Suite, etc. (Optional)</label>
        <input
          type="text"
          id="streetAddress2"
          name="streetAddress2"
          value={formData.streetAddress2}
          onChange={handleChange}
          placeholder="Apt 4B"
        />
      </div>
      
      <div className="form-row">
        <div className="form-group" style={{ flex: 2 }}>
          <label htmlFor="city">City</label>
          <input
            type="text"
            id="city"
            name="city"
            value={formData.city}
            onChange={handleChange}
            placeholder="New York"
          />
          {errors.city && <div className="error-message">{errors.city}</div>}
        </div>
        
        <div className="form-group" style={{ flex: 1 }}>
          <label htmlFor="state">State</label>
          <select
            id="state"
            name="state"
            value={formData.state}
            onChange={handleChange}
          >
            <option value="">Select State</option>
            {US_STATES.map(state => (
              <option key={state.code} value={state.code}>
                {state.name}
              </option>
            ))}
          </select>
          {errors.state && <div className="error-message">{errors.state}</div>}
        </div>
        
        <div className="form-group" style={{ flex: 1 }}>
          <label htmlFor="zipCode">ZIP Code</label>
          <input
            type="text"
            id="zipCode"
            name="zipCode"
            value={formData.zipCode}
            onChange={handleChange}
            placeholder="10001"
          />
          {errors.zipCode && <div className="error-message">{errors.zipCode}</div>}
        </div>
      </div>
      
      <div className="checkbox-group">
        <input
          type="checkbox"
          id="isMailingSame"
          name="isMailingSame"
          checked={formData.isMailingSame}
          onChange={handleChange}
        />
        <label htmlFor="isMailingSame">
          My mailing address is the same as my residential address
        </label>
      </div>
      
      {!formData.isMailingSame && (
        <>
          <h2>Mailing Address</h2>
          
          <div className="form-group">
            <label htmlFor="mailing.streetAddress">Street Address</label>
            <input
              type="text"
              id="mailing.streetAddress"
              name="mailing.streetAddress"
              value={formData.mailingAddress?.streetAddress || ''}
              onChange={handleChange}
              placeholder="123 Main Street"
            />
            {errors['mailing.streetAddress'] && (
              <div className="error-message">{errors['mailing.streetAddress']}</div>
            )}
          </div>
          
          <div className="form-group">
            <label htmlFor="mailing.streetAddress2">Apartment, Suite, etc. (Optional)</label>
            <input
              type="text"
              id="mailing.streetAddress2"
              name="mailing.streetAddress2"
              value={formData.mailingAddress?.streetAddress2 || ''}
              onChange={handleChange}
              placeholder="Apt 4B"
            />
          </div>
          
          <div className="form-row">
            <div className="form-group" style={{ flex: 2 }}>
              <label htmlFor="mailing.city">City</label>
              <input
                type="text"
                id="mailing.city"
                name="mailing.city"
                value={formData.mailingAddress?.city || ''}
                onChange={handleChange}
                placeholder="New York"
              />
              {errors['mailing.city'] && (
                <div className="error-message">{errors['mailing.city']}</div>
              )}
            </div>
            
            <div className="form-group" style={{ flex: 1 }}>
              <label htmlFor="mailing.state">State</label>
              <select
                id="mailing.state"
                name="mailing.state"
                value={formData.mailingAddress?.state || ''}
                onChange={handleChange}
              >
                <option value="">Select State</option>
                {US_STATES.map(state => (
                  <option key={state.code} value={state.code}>
                    {state.name}
                  </option>
                ))}
              </select>
              {errors['mailing.state'] && (
                <div className="error-message">{errors['mailing.state']}</div>
              )}
            </div>
            
            <div className="form-group" style={{ flex: 1 }}>
              <label htmlFor="mailing.zipCode">ZIP Code</label>
              <input
                type="text"
                id="mailing.zipCode"
                name="mailing.zipCode"
                value={formData.mailingAddress?.zipCode || ''}
                onChange={handleChange}
                placeholder="10001"
              />
              {errors['mailing.zipCode'] && (
                <div className="error-message">{errors['mailing.zipCode']}</div>
              )}
            </div>
          </div>
        </>
      )}
      
      <div className="onboarding-screen-footer">
        <button className="btn-primary" onClick={handleSubmit}>
          Continue
        </button>
      </div>
    </div>
  );
};

export default AddressScreen;