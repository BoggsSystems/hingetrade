import React, { createContext, useContext, useEffect, useState, useCallback } from 'react';
import { api } from '../services/api';
import type { User } from '../types';
import { debugLogger } from '../utils/debugLogger';

interface AuthContextType {
  isAuthenticated: boolean;
  isLoading: boolean;
  user: User | null;
  login: (email: string, password: string) => Promise<void>;
  register: (email: string, password: string, username: string) => Promise<User>;
  logout: () => Promise<void>;
  getAccessToken: () => Promise<string | null>;
  refreshAccessToken: () => Promise<void>;
}

interface AuthTokens {
  accessToken: string;
  refreshToken: string;
  expiresAt: number;
}

interface LoginResponse {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
  user: {
    id: string;
    email: string;
    username: string;
    emailVerified: boolean;
    roles: string[];
    kycStatus: string;
    kycSubmittedAt?: string;
    kycApprovedAt?: string;
    createdAt: string;
  };
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

const TOKEN_KEY = 'auth_tokens';
const USER_KEY = 'auth_user';

export const AuthProvider: React.FC<AuthProviderProps> = ({ children }) => {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [user, setUser] = useState<User | null>(null);
  const [tokens, setTokens] = useState<AuthTokens | null>(null);
  const [, setInitialLoadComplete] = useState(false);

  const clearAuthState = () => {
    localStorage.removeItem(TOKEN_KEY);
    localStorage.removeItem(USER_KEY);
    delete api.defaults.headers.common['Authorization'];
    setTokens(null);
    setUser(null);
    setIsAuthenticated(false);
  };

  const saveAuthState = (authTokens: AuthTokens, authUser: User) => {
    localStorage.setItem(TOKEN_KEY, JSON.stringify(authTokens));
    localStorage.setItem(USER_KEY, JSON.stringify(authUser));
    api.defaults.headers.common['Authorization'] = `Bearer ${authTokens.accessToken}`;
    setTokens(authTokens);
    setUser(authUser);
    setIsAuthenticated(true);
  };

  const login = async (email: string, password: string) => {
    try {
      const response = await api.post<LoginResponse>('/auth/login', {
        emailOrUsername: email,
        password,
      });

      const { accessToken, refreshToken, expiresIn, user: apiUser } = response.data;

      const authTokens: AuthTokens = {
        accessToken,
        refreshToken,
        expiresAt: Date.now() + expiresIn * 1000,
      };

      const mappedUser: User = {
        id: apiUser.id.toString(),
        email: apiUser.email,
        username: apiUser.username,
        emailVerified: apiUser.emailVerified,
        kycStatus: apiUser.kycStatus as any,
        kycSubmittedAt: apiUser.kycSubmittedAt,
        kycApprovedAt: apiUser.kycApprovedAt,
        createdAt: apiUser.createdAt,
        roles: apiUser.roles,
      };

      saveAuthState(authTokens, mappedUser);
    } catch (error) {
      console.error('Login error:', error);
      throw error;
    }
  };

  const register = async (email: string, password: string, username: string) => {
    try {
      debugLogger.info('AuthContext register called', { email, username });
      
      debugLogger.info('Making API call to /auth/register...');
      const response = await api.post<LoginResponse>('/auth/register', {
        email,
        password,
        username,
      });
      debugLogger.info('API call completed, processing response...');

      debugLogger.info('Registration API call successful', { 
        status: response.status, 
        hasData: !!response.data,
        hasUser: !!response.data.user 
      });

      const { accessToken, refreshToken, expiresIn, user: apiUser } = response.data;

      const authTokens: AuthTokens = {
        accessToken,
        refreshToken,
        expiresAt: Date.now() + expiresIn * 1000,
      };

      const mappedUser: User = {
        id: apiUser.id.toString(),
        email: apiUser.email,
        username: apiUser.username,
        emailVerified: apiUser.emailVerified,
        kycStatus: apiUser.kycStatus as any,
        kycSubmittedAt: apiUser.kycSubmittedAt,
        kycApprovedAt: apiUser.kycApprovedAt,
        createdAt: apiUser.createdAt,
        roles: apiUser.roles,
      };

      debugLogger.info('About to save auth state', { userId: mappedUser.id, userEmail: mappedUser.email });
      saveAuthState(authTokens, mappedUser);
      debugLogger.info('Auth state saved successfully');
      
      return mappedUser;
    } catch (error) {
      debugLogger.error('Registration error in AuthContext', error);
      throw error;
    }
  };

  const logout = async () => {
    try {
      // Call logout endpoint to invalidate refresh token
      if (tokens?.refreshToken) {
        await api.post('/auth/logout', {
          refreshToken: tokens.refreshToken,
        });
      }
    } catch (error) {
      console.error('Logout error:', error);
    } finally {
      clearAuthState();
    }
  };

  const refreshAccessToken = useCallback(async () => {
    try {
      const storedTokens = localStorage.getItem(TOKEN_KEY);
      if (!storedTokens) {
        throw new Error('No refresh token available');
      }

      const parsedTokens = JSON.parse(storedTokens) as AuthTokens;
      
      const response = await api.post<LoginResponse>('/auth/refresh', {
        refreshToken: parsedTokens.refreshToken,
      });

      const { accessToken, refreshToken, expiresIn, user: apiUser } = response.data;

      const authTokens: AuthTokens = {
        accessToken,
        refreshToken,
        expiresAt: Date.now() + expiresIn * 1000,
      };

      const mappedUser: User = {
        id: apiUser.id.toString(),
        email: apiUser.email,
        username: apiUser.username,
        emailVerified: apiUser.emailVerified,
        kycStatus: apiUser.kycStatus as any,
        kycSubmittedAt: apiUser.kycSubmittedAt,
        kycApprovedAt: apiUser.kycApprovedAt,
        createdAt: apiUser.createdAt,
        roles: apiUser.roles,
      };

      saveAuthState(authTokens, mappedUser);
    } catch (error) {
      console.error('Token refresh error:', error);
      clearAuthState();
      throw error;
    }
  }, []);

  const getAccessToken = async () => {
    if (!tokens) {
      return null;
    }

    // Check if token is expired
    if (tokens.expiresAt <= Date.now() + 60000) { // Refresh if expiring in 1 minute
      await refreshAccessToken();
    }

    return tokens?.accessToken || null;
  };

  // Set up axios interceptor for token refresh
  useEffect(() => {
    const interceptor = api.interceptors.response.use(
      (response) => response,
      async (error) => {
        const originalRequest = error.config;

        if (error.response?.status === 401 && !originalRequest._retry) {
          originalRequest._retry = true;

          try {
            await refreshAccessToken();
            const newToken = await getAccessToken();
            originalRequest.headers['Authorization'] = `Bearer ${newToken}`;
            return api(originalRequest);
          } catch (refreshError) {
            clearAuthState();
            window.location.href = '/';
            return Promise.reject(refreshError);
          }
        }

        return Promise.reject(error);
      }
    );

    return () => {
      api.interceptors.response.eject(interceptor);
    };
  }, [refreshAccessToken, getAccessToken]);

  // Load auth state from localStorage on mount
  useEffect(() => {
    const loadAuthState = () => {
      try {
        const storedTokens = localStorage.getItem(TOKEN_KEY);
        const storedUser = localStorage.getItem(USER_KEY);

        if (storedTokens && storedUser) {
          const parsedTokens = JSON.parse(storedTokens) as AuthTokens;
          const parsedUser = JSON.parse(storedUser) as User;

          // Check if token is expired
          if (parsedTokens.expiresAt > Date.now()) {
            setTokens(parsedTokens);
            setUser(parsedUser);
            setIsAuthenticated(true);
            
            // Set authorization header
            api.defaults.headers.common['Authorization'] = `Bearer ${parsedTokens.accessToken}`;
          } else {
            // Token expired, clear state
            clearAuthState();
          }
        }
      } catch (error) {
        console.error('Error loading auth state:', error);
        clearAuthState();
      } finally {
        setIsLoading(false);
        setInitialLoadComplete(true);
      }
    };

    loadAuthState();
  }, []);

  const value: AuthContextType = {
    isAuthenticated,
    isLoading,
    user,
    login,
    register,
    logout,
    getAccessToken,
    refreshAccessToken,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};