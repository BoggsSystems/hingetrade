import React, { createContext, useContext, useState } from 'react';
import type { User } from '../types';

interface AuthContextType {
  isAuthenticated: boolean;
  isLoading: boolean;
  user: User | null;
  login: () => void;
  logout: () => void;
  getAccessToken: () => Promise<string>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

interface AuthProviderProps {
  children: React.ReactNode;
}

// Development Auth Provider - No Auth0 Required
export const AuthProvider: React.FC<AuthProviderProps> = ({ children }) => {
  // Auto-login for development
  const mockUser: User = {
    id: 'dev-user-123',
    email: 'demo@hingetrade.com',
    name: 'Demo User',
    emailVerified: true,
    picture: 'https://ui-avatars.com/api/?name=Demo+User',
    alpacaAccountId: 'mock-alpaca-id',
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  };
  
  const [isAuthenticated, setIsAuthenticated] = useState(true);
  const [user, setUser] = useState<User | null>(mockUser);
  
  // Set auth token on init
  React.useEffect(() => {
    localStorage.setItem('authToken', 'mock-jwt-token');
  }, []);

  const login = () => {
    // Mock user for development
    const mockUser: User = {
      id: 'dev-user-123',
      email: 'demo@hingetrade.com',
      name: 'Demo User',
      emailVerified: true,
      picture: 'https://ui-avatars.com/api/?name=Demo+User',
      alpacaAccountId: 'mock-alpaca-id',
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };
    setUser(mockUser);
    setIsAuthenticated(true);
    localStorage.setItem('authToken', 'mock-jwt-token');
  };

  const logout = () => {
    setUser(null);
    setIsAuthenticated(false);
    localStorage.removeItem('authToken');
  };

  const getAccessToken = async () => {
    return 'mock-jwt-token';
  };

  const value: AuthContextType = {
    isAuthenticated,
    isLoading: false,
    user,
    login,
    logout,
    getAccessToken,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};