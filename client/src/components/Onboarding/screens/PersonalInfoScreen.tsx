import React, { useState } from 'react';

interface PersonalInfoScreenProps {
  onNext: (data: PersonalInfoData) => void;
  data?: Partial<PersonalInfoData>;
}

interface PersonalInfoData {
  firstName: string;
  lastName: string;
  dateOfBirth: string;
  phoneNumber: string;
  email: string;
}

const PersonalInfoScreen: React.FC<PersonalInfoScreenProps> = ({ onNext, data }) => {
  // Generate test data for development
  const generateTestData = (): Partial<PersonalInfoData> => {
    const firstNames = ['John', 'Jane', 'Michael', 'Sarah', 'David', 'Emily', 'Robert', 'Lisa'];
    const lastNames = ['Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis'];
    
    const randomFirst = firstNames[Math.floor(Math.random() * firstNames.length)];
    const randomLast = lastNames[Math.floor(Math.random() * lastNames.length)];
    
    // Generate a random birth date (between 25-65 years old)
    const minAge = 25;
    const maxAge = 65;
    const randomAge = Math.floor(Math.random() * (maxAge - minAge + 1)) + minAge;
    const birthYear = new Date().getFullYear() - randomAge;
    const birthMonth = String(Math.floor(Math.random() * 12) + 1).padStart(2, '0');
    const birthDay = String(Math.floor(Math.random() * 28) + 1).padStart(2, '0');
    
    return {
      firstName: randomFirst,
      lastName: randomLast,
      dateOfBirth: `${birthYear}-${birthMonth}-${birthDay}`,
      phoneNumber: `(555) ${String(Math.floor(Math.random() * 900) + 100)}-${String(Math.floor(Math.random() * 9000) + 1000)}`
    };
  };

  const testData = data?.firstName ? {} : generateTestData();

  const [formData, setFormData] = useState<PersonalInfoData>({
    firstName: data?.firstName || testData.firstName || '',
    lastName: data?.lastName || testData.lastName || '',
    dateOfBirth: data?.dateOfBirth || testData.dateOfBirth || '',
    phoneNumber: data?.phoneNumber || testData.phoneNumber || '',
    email: data?.email || ''
  });
  
  const [errors, setErrors] = useState<Partial<PersonalInfoData>>({});
  
  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
    // Clear error when user starts typing
    if (errors[name as keyof PersonalInfoData]) {
      setErrors(prev => ({ ...prev, [name]: '' }));
    }
  };
  
  const validateForm = () => {
    const newErrors: Partial<PersonalInfoData> = {};
    
    if (!formData.firstName.trim()) {
      newErrors.firstName = 'First name is required';
    }
    if (!formData.lastName.trim()) {
      newErrors.lastName = 'Last name is required';
    }
    if (!formData.dateOfBirth) {
      newErrors.dateOfBirth = 'Date of birth is required';
    } else {
      const age = new Date().getFullYear() - new Date(formData.dateOfBirth).getFullYear();
      if (age < 18) {
        newErrors.dateOfBirth = 'You must be at least 18 years old';
      }
    }
    if (!formData.phoneNumber.trim()) {
      newErrors.phoneNumber = 'Phone number is required';
    }
    if (!formData.email.trim()) {
      newErrors.email = 'Email is required';
    } else if (!/\S+@\S+\.\S+/.test(formData.email)) {
      newErrors.email = 'Invalid email address';
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
      <h1>Personal Information</h1>
      <p>Let's start with your basic information.</p>
      
      <div className="form-row">
        <div className="form-group" style={{ flex: 1 }}>
          <label htmlFor="firstName">First Name</label>
          <input
            type="text"
            id="firstName"
            name="firstName"
            value={formData.firstName}
            onChange={handleChange}
            placeholder="John"
          />
          {errors.firstName && <div className="error-message">{errors.firstName}</div>}
        </div>
        
        <div className="form-group" style={{ flex: 1 }}>
          <label htmlFor="lastName">Last Name</label>
          <input
            type="text"
            id="lastName"
            name="lastName"
            value={formData.lastName}
            onChange={handleChange}
            placeholder="Doe"
          />
          {errors.lastName && <div className="error-message">{errors.lastName}</div>}
        </div>
      </div>
      
      <div className="form-group">
        <label htmlFor="dateOfBirth">Date of Birth</label>
        <input
          type="date"
          id="dateOfBirth"
          name="dateOfBirth"
          value={formData.dateOfBirth}
          onChange={handleChange}
          max={new Date().toISOString().split('T')[0]}
        />
        {errors.dateOfBirth && <div className="error-message">{errors.dateOfBirth}</div>}
        <div className="help-text">You must be at least 18 years old to open an account</div>
      </div>
      
      <div className="form-group">
        <label htmlFor="phoneNumber">Phone Number</label>
        <input
          type="tel"
          id="phoneNumber"
          name="phoneNumber"
          value={formData.phoneNumber}
          onChange={handleChange}
          placeholder="(555) 123-4567"
        />
        {errors.phoneNumber && <div className="error-message">{errors.phoneNumber}</div>}
      </div>
      
      <div className="form-group">
        <label htmlFor="email">Email Address</label>
        <input
          type="email"
          id="email"
          name="email"
          value={formData.email}
          onChange={handleChange}
          placeholder="john.doe@example.com"
        />
        {errors.email && <div className="error-message">{errors.email}</div>}
        <div className="help-text">We'll use this to send important account notifications</div>
      </div>
      
      <div className="onboarding-screen-footer">
        <button className="btn-primary" onClick={handleSubmit}>
          Continue
        </button>
      </div>
    </div>
  );
};

export default PersonalInfoScreen;