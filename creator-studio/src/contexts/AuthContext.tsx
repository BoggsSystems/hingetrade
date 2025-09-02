'use client';

import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { useRouter } from 'next/navigation';
import { apiClient } from '@/lib/api';

export interface User {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
  fullName: string;
  role: string;
}

interface AuthContextType {
  user: User | null;
  login: (email: string, password: string, redirectTo?: string) => Promise<void>;
  register: (email: string, firstName: string, lastName: string, password: string, redirectTo?: string) => Promise<void>;
  logout: () => void;
  isLoading: boolean;
  isAuthenticated: boolean;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function useAuth() {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}

interface AuthProviderProps {
  children: ReactNode;
}


export function AuthProvider({ children }: AuthProviderProps) {
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const router = useRouter();

  useEffect(() => {
    checkAuthStatus();
  }, []);

  const checkAuthStatus = async () => {
    try {
      const token = localStorage.getItem('accessToken');
      if (!token) {
        setIsLoading(false);
        return;
      }

      // For now, we'll decode the token to get user info
      // In production, you might want to validate with the server
      try {
        const tokenPayload = JSON.parse(atob(token.split('.')[1]));
        const user: User = {
          id: tokenPayload.nameid,
          email: tokenPayload.email,
          firstName: tokenPayload.firstName,
          lastName: tokenPayload.lastName,
          fullName: `${tokenPayload.firstName} ${tokenPayload.lastName}`,
          role: tokenPayload.role,
        };
        setUser(user);
      } catch {
        localStorage.removeItem('accessToken');
      }
    } catch (error) {
      console.error('Auth check failed:', error);
      localStorage.removeItem('accessToken');
    } finally {
      setIsLoading(false);
    }
  };

  const login = async (email: string, password: string, redirectTo?: string) => {
    setIsLoading(true);
    try {
      const response = await apiClient.post<{ accessToken: string; user: User }>('/auth/login', {
        email,
        password,
      });

      localStorage.setItem('accessToken', response.accessToken);
      setUser(response.user);
      
      // Navigate to redirect destination or default to dashboard
      router.push(redirectTo || '/dashboard');
    } catch (error) {
      throw error;
    } finally {
      setIsLoading(false);
    }
  };

  const register = async (email: string, firstName: string, lastName: string, password: string, redirectTo?: string) => {
    setIsLoading(true);
    try {
      const response = await apiClient.post<{ accessToken: string; user: User }>('/auth/register', {
        email,
        firstName,
        lastName,
        password,
      });

      localStorage.setItem('accessToken', response.accessToken);
      setUser(response.user);
      
      // Navigate to redirect destination or default to dashboard
      router.push(redirectTo || '/dashboard');
    } catch (error) {
      throw error;
    } finally {
      setIsLoading(false);
    }
  };

  const logout = async () => {
    try {
      await apiClient.post('/auth/logout');
    } catch (error) {
      console.error('Logout request failed:', error);
    }

    localStorage.removeItem('accessToken');
    setUser(null);
    router.push('/login');
  };

  const value = {
    user,
    login,
    register,
    logout,
    isLoading,
    isAuthenticated: !!user,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}