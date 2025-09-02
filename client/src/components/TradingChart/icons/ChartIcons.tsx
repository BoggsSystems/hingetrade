import React from 'react';

interface IconProps {
  size?: number;
  className?: string;
}

export const CandlestickIcon: React.FC<IconProps> = ({ size = 16, className }) => (
  <svg 
    width={size} 
    height={size} 
    viewBox="0 0 16 16" 
    fill="none" 
    className={className}
    xmlns="http://www.w3.org/2000/svg"
  >
    {/* Candlestick wicks */}
    <path
      d="M3 1.5V3.5M3 8.5V14.5M7 1V4.5M7 9.5V15M11 2V4M11 10V14"
      stroke="currentColor"
      strokeWidth="1"
      strokeLinecap="round"
    />
    {/* Candlestick bodies */}
    <rect x="2.25" y="3.5" width="1.5" height="5" fill="currentColor" rx="0.2" />
    <rect x="6.25" y="4.5" width="1.5" height="5" fill="currentColor" rx="0.2" />
    <rect x="10.25" y="4" width="1.5" height="6" fill="currentColor" rx="0.2" />
  </svg>
);

export const OHLCIcon: React.FC<IconProps> = ({ size = 16, className }) => (
  <svg 
    width={size} 
    height={size} 
    viewBox="0 0 16 16" 
    fill="none" 
    className={className}
    xmlns="http://www.w3.org/2000/svg"
  >
    {/* Vertical lines */}
    <path
      d="M3 2V14M7 3V13M11 4V12M15 2.5V13.5"
      stroke="currentColor"
      strokeWidth="1"
      strokeLinecap="round"
    />
    {/* Open/Close marks */}
    <path
      d="M1.5 4H3M3 10H4.5M5.5 5H7M7 11H8.5M9.5 6H11M11 8H12.5M13.5 3H15M15 11H16"
      stroke="currentColor"
      strokeWidth="1"
      strokeLinecap="round"
    />
  </svg>
);

export const LineIcon: React.FC<IconProps> = ({ size = 16, className }) => (
  <svg 
    width={size} 
    height={size} 
    viewBox="0 0 16 16" 
    fill="none" 
    className={className}
    xmlns="http://www.w3.org/2000/svg"
  >
    <path
      d="M1.5 13L4.5 9L7.5 11L10.5 6L14.5 3"
      stroke="currentColor"
      strokeWidth="1.5"
      strokeLinecap="round"
      strokeLinejoin="round"
    />
    <circle cx="1.5" cy="13" r="1" fill="currentColor" />
    <circle cx="4.5" cy="9" r="1" fill="currentColor" />
    <circle cx="7.5" cy="11" r="1" fill="currentColor" />
    <circle cx="10.5" cy="6" r="1" fill="currentColor" />
    <circle cx="14.5" cy="3" r="1" fill="currentColor" />
  </svg>
);

export const VolumeIcon: React.FC<IconProps> = ({ size = 16, className }) => (
  <svg 
    width={size} 
    height={size} 
    viewBox="0 0 16 16" 
    fill="none" 
    className={className}
    xmlns="http://www.w3.org/2000/svg"
  >
    <rect x="1" y="11" width="2" height="4" fill="currentColor" rx="0.3" />
    <rect x="4" y="9" width="2" height="6" fill="currentColor" rx="0.3" />
    <rect x="7" y="6" width="2" height="9" fill="currentColor" rx="0.3" />
    <rect x="10" y="4" width="2" height="11" fill="currentColor" rx="0.3" />
    <rect x="13" y="8" width="2" height="7" fill="currentColor" rx="0.3" />
  </svg>
);

export const AreaIcon: React.FC<IconProps> = ({ size = 16, className }) => (
  <svg 
    width={size} 
    height={size} 
    viewBox="0 0 16 16" 
    fill="none" 
    className={className}
    xmlns="http://www.w3.org/2000/svg"
  >
    <path
      d="M1 12L4 8L7 10L11 6L15 4V14H1V12Z"
      fill="currentColor"
      fillOpacity="0.3"
    />
    <path
      d="M1 12L4 8L7 10L11 6L15 4"
      stroke="currentColor"
      strokeWidth="1.5"
      strokeLinecap="round"
      strokeLinejoin="round"
    />
  </svg>
);