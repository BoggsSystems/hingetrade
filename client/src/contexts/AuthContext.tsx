import React, { createContext, useContext, useEffect, useState } from 'react';
import { useAuth0 } from '@auth0/auth0-react';
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

export const AuthProvider: React.FC<AuthProviderProps> = ({ children }) => {
  const {
    isAuthenticated,
    isLoading,
    user: auth0User,
    loginWithRedirect,
    logout: auth0Logout,
    getAccessTokenSilently,
  } = useAuth0();

  const [user, setUser] = useState<User | null>(null);

  useEffect(() => {
    if (isAuthenticated && auth0User) {
      // Map Auth0 user to our User type
      const mappedUser: User = {
        id: auth0User.sub || '',
        email: auth0User.email || '',
        name: auth0User.name || '',
        emailVerified: auth0User.email_verified || false,
        picture: auth0User.picture,
        alpacaAccountId: auth0User['alpaca_account_id'],
        createdAt: auth0User.created_at || new Date().toISOString(),
        updatedAt: auth0User.updated_at || new Date().toISOString(),
      };
      setUser(mappedUser);

      // Store the access token for API requests
      getAccessTokenSilently().then((token) => {
        localStorage.setItem('authToken', token);
      });
    } else {
      setUser(null);
      localStorage.removeItem('authToken');
    }
  }, [isAuthenticated, auth0User, getAccessTokenSilently]);

  const login = () => {
    loginWithRedirect({
      appState: { returnTo: window.location.pathname },
    });
  };

  const logout = () => {
    auth0Logout({
      logoutParams: {
        returnTo: window.location.origin,
      },
    });
  };

  const getAccessToken = async () => {
    try {
      const token = await getAccessTokenSilently();
      return token;
    } catch (error) {
      console.error('Error getting access token:', error);
      throw error;
    }
  };

  const value: AuthContextType = {
    isAuthenticated,
    isLoading,
    user,
    login,
    logout,
    getAccessToken,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};