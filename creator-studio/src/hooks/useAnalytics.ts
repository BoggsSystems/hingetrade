import { useState, useEffect } from 'react';

export interface DashboardAnalytics {
  totalVideos: number;
  publishedVideos: number;
  totalViews: number;
  uniqueViews: number;
  totalWatchTimeHours: number;
  subscribers: number;
  revenue: number;
  monthlyGrowthPercentage: number;
  thisMonth: {
    views: number;
    watchTimeHours: number;
    revenue: number;
    viewsGrowthPercentage: number;
    watchTimeGrowthPercentage: number;
    revenueGrowthPercentage: number;
  };
  topVideos: Array<{
    id: string;
    title: string;
    thumbnailUrl?: string;
    views: number;
    watchTimeHours: number;
    engagementRate: number;
  }>;
}

export interface VideoAnalytics {
  videoId: string;
  title: string;
  thumbnailUrl?: string;
  createdAt: string;
  views: number;
  uniqueViews: number;
  averageWatchTimeSeconds: number;
  totalWatchTimeHours: number;
  completionRate: number;
  engagementRate: number;
  likes: number;
  shares: number;
  comments: number;
  trafficSources: Record<string, number>;
  deviceTypes: Record<string, number>;
  dailyViews: Array<{
    date: string;
    views: number;
    watchTimeHours: number;
  }>;
}

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:5155/api';

export function useAnalytics() {
  const [dashboardData, setDashboardData] = useState<DashboardAnalytics | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);


  const fetchDashboardAnalytics = async () => {
    try {
      setLoading(true);
      setError(null);

      const token = localStorage.getItem('accessToken');
      if (!token) {
        throw new Error('No authentication token found');
      }

      const response = await fetch(`${API_BASE_URL}/analytics/dashboard`, {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
      });

      if (!response.ok) {
        if (response.status === 401) {
          throw new Error('Authentication failed. Please log in again.');
        }
        throw new Error(`Failed to fetch analytics: ${response.statusText}`);
      }

      const data = await response.json();
      setDashboardData(data);
    } catch (err) {
      console.error('Error fetching dashboard analytics:', err);
      setError(err instanceof Error ? err.message : 'Unknown error occurred');
      
      // Fallback to empty data on error
      setDashboardData({
        totalVideos: 0,
        publishedVideos: 0,
        totalViews: 0,
        uniqueViews: 0,
        totalWatchTimeHours: 0,
        subscribers: 0,
        revenue: 0,
        monthlyGrowthPercentage: 0,
        thisMonth: {
          views: 0,
          watchTimeHours: 0,
          revenue: 0,
          viewsGrowthPercentage: 0,
          watchTimeGrowthPercentage: 0,
          revenueGrowthPercentage: 0,
        },
        topVideos: [],
      });
    } finally {
      setLoading(false);
    }
  };

  const fetchVideoAnalytics = async (videoId: string): Promise<VideoAnalytics | null> => {
    try {
      const token = localStorage.getItem('accessToken');
      if (!token) {
        throw new Error('No authentication token found');
      }

      const response = await fetch(`${API_BASE_URL}/analytics/videos/${videoId}`, {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
      });

      if (!response.ok) {
        throw new Error(`Failed to fetch video analytics: ${response.statusText}`);
      }

      return await response.json();
    } catch (err) {
      console.error('Error fetching video analytics:', err);
      return null;
    }
  };

  useEffect(() => {
    fetchDashboardAnalytics();
  }, []);

  const refresh = () => {
    fetchDashboardAnalytics();
  };

  return {
    dashboardData,
    loading,
    error,
    refresh,
    fetchVideoAnalytics,
  };
}