import React, { useState, useRef, useEffect, useCallback } from 'react';
import VideoPlayer from './VideoPlayer';

interface VideoPlayerWithTrackingProps {
  videoId: string;
  src?: string;
  poster?: string;
  title: string;
  isActive: boolean;
  autoplay: boolean;
  volume: number;
  duration?: number;
  onPlay?: () => void;
  onPause?: () => void;
  onEnded?: () => void;
  className?: string;
  // View tracking API base URL
  apiBaseUrl?: string;
}

interface ViewSession {
  sessionId: string;
  startTime: number;
  lastUpdateTime: number;
  totalWatchTime: number;
  maxWatchTime: number;
  isActive: boolean;
}

export const VideoPlayerWithTracking: React.FC<VideoPlayerWithTrackingProps> = ({
  videoId,
  src,
  poster,
  title,
  isActive,
  autoplay,
  volume,
  duration: videoDuration,
  onPlay,
  onPause,
  onEnded,
  className,
  apiBaseUrl = 'http://localhost:5155/api'
}) => {
  const [viewSession, setViewSession] = useState<ViewSession | null>(null);
  const [currentTime, setCurrentTime] = useState(0);
  const [duration, setDuration] = useState(videoDuration || 0);
  const [hasStartedTracking, setHasStartedTracking] = useState(false);
  const updateIntervalRef = useRef<number | null>(null);
  const lastUpdateRef = useRef<number>(0);

  // Get anonymous ID from localStorage or create new one
  const getAnonymousId = () => {
    let anonymousId = localStorage.getItem('anonymous_id');
    if (!anonymousId) {
      anonymousId = `anon_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
      localStorage.setItem('anonymous_id', anonymousId);
    }
    return anonymousId;
  };

  // Start view session
  const startViewSession = useCallback(async () => {
    if (hasStartedTracking || !videoId) return;

    try {
      const token = localStorage.getItem('token');
      const headers: HeadersInit = {
        'Content-Type': 'application/json'
      };
      
      if (token) {
        headers['Authorization'] = `Bearer ${token}`;
      }

      const response = await fetch(`${apiBaseUrl}/videos/${videoId}/views/start`, {
        method: 'POST',
        headers,
        body: JSON.stringify({
          videoId,
          anonymousId: getAnonymousId(),
          deviceType: /Mobile|Android|iPhone/i.test(navigator.userAgent) ? 'mobile' : 'desktop',
          trafficSource: document.referrer ? 'referral' : 'direct'
        })
      });

      if (response.ok) {
        const data = await response.json();
        if (data.success) {
          const session: ViewSession = {
            sessionId: data.sessionId,
            startTime: Date.now(),
            lastUpdateTime: Date.now(),
            totalWatchTime: 0,
            maxWatchTime: 0,
            isActive: true
          };
          setViewSession(session);
          setHasStartedTracking(true);
          
          // Store session in localStorage for recovery
          localStorage.setItem(`view_session_${videoId}`, JSON.stringify(session));
          
          console.log('[VideoTracking] Started view session:', data.sessionId);
        }
      }
    } catch (error) {
      console.error('[VideoTracking] Failed to start view session:', error);
    }
  }, [videoId, apiBaseUrl, hasStartedTracking]);

  // Update view progress
  const updateViewProgress = useCallback(async (isPaused: boolean = false) => {
    if (!viewSession || !viewSession.isActive || currentTime === lastUpdateRef.current) return;

    const now = Date.now();
    const timeSinceLastUpdate = (now - viewSession.lastUpdateTime) / 1000;
    const newTotalWatchTime = viewSession.totalWatchTime + (isPaused ? 0 : timeSinceLastUpdate);
    const newMaxWatchTime = Math.max(viewSession.maxWatchTime, currentTime);
    const watchPercentage = duration > 0 ? (currentTime / duration) * 100 : 0;

    lastUpdateRef.current = currentTime;

    try {
      const token = localStorage.getItem('token');
      const headers: HeadersInit = {
        'Content-Type': 'application/json'
      };
      
      if (token) {
        headers['Authorization'] = `Bearer ${token}`;
      }

      const response = await fetch(`${apiBaseUrl}/videos/${videoId}/views/${viewSession.sessionId}`, {
        method: 'PUT',
        headers,
        body: JSON.stringify({
          sessionId: viewSession.sessionId,
          watchTimeSeconds: newTotalWatchTime,
          maxWatchTimeSeconds: newMaxWatchTime,
          watchPercentage,
          isPaused
        })
      });

      if (response.ok) {
        const updatedSession = {
          ...viewSession,
          lastUpdateTime: now,
          totalWatchTime: newTotalWatchTime,
          maxWatchTime: newMaxWatchTime
        };
        setViewSession(updatedSession);
        
        // Update localStorage
        localStorage.setItem(`view_session_${videoId}`, JSON.stringify(updatedSession));
      } else if (response.status === 410) {
        // Session expired
        console.log('[VideoTracking] Session expired, starting new session');
        setViewSession(null);
        setHasStartedTracking(false);
        await startViewSession();
      }
    } catch (error) {
      console.error('[VideoTracking] Failed to update view progress:', error);
    }
  }, [viewSession, currentTime, duration, videoId, apiBaseUrl, startViewSession]);

  // Complete view session
  const completeViewSession = useCallback(async () => {
    if (!viewSession) return;

    const completed = currentTime >= duration * 0.8; // 80% completion threshold
    const finalWatchTime = viewSession.totalWatchTime + ((Date.now() - viewSession.lastUpdateTime) / 1000);

    try {
      const token = localStorage.getItem('token');
      const headers: HeadersInit = {
        'Content-Type': 'application/json'
      };
      
      if (token) {
        headers['Authorization'] = `Bearer ${token}`;
      }

      await fetch(`${apiBaseUrl}/videos/${videoId}/views/complete`, {
        method: 'POST',
        headers,
        body: JSON.stringify({
          sessionId: viewSession.sessionId,
          finalWatchTimeSeconds: finalWatchTime,
          maxWatchTimeSeconds: Math.max(viewSession.maxWatchTime, currentTime),
          completed
        })
      });

      console.log('[VideoTracking] Completed view session:', viewSession.sessionId);
    } catch (error) {
      console.error('[VideoTracking] Failed to complete view session:', error);
    } finally {
      // Clear session
      setViewSession(null);
      setHasStartedTracking(false);
      localStorage.removeItem(`view_session_${videoId}`);
    }
  }, [viewSession, currentTime, duration, videoId, apiBaseUrl]);

  // Handle play event
  const handlePlay = useCallback(() => {
    if (!hasStartedTracking && isActive) {
      startViewSession();
    }
    onPlay?.();
  }, [hasStartedTracking, isActive, startViewSession, onPlay]);

  // Handle pause event
  const handlePause = useCallback(() => {
    updateViewProgress(true);
    onPause?.();
  }, [updateViewProgress, onPause]);

  // Handle ended event
  const handleEnded = useCallback(() => {
    completeViewSession();
    onEnded?.();
  }, [completeViewSession, onEnded]);

  // Handle time update
  const handleTimeUpdate = useCallback((time: number, dur: number) => {
    setCurrentTime(time);
    setDuration(dur);
  }, []);

  // Set up progress update interval
  useEffect(() => {
    if (viewSession && viewSession.isActive && isActive) {
      updateIntervalRef.current = setInterval(() => {
        updateViewProgress();
      }, 10000); // Update every 10 seconds

      return () => {
        if (updateIntervalRef.current) {
          clearInterval(updateIntervalRef.current);
        }
      };
    }
  }, [viewSession, isActive, updateViewProgress]);

  // Handle component unmount or video change
  useEffect(() => {
    return () => {
      if (viewSession && viewSession.isActive) {
        completeViewSession();
      }
    };
  }, [videoId]); // Only run when videoId changes

  // Recover session from localStorage
  useEffect(() => {
    const storedSession = localStorage.getItem(`view_session_${videoId}`);
    if (storedSession && !viewSession) {
      try {
        const session = JSON.parse(storedSession) as ViewSession;
        // Check if session is recent (within 30 minutes)
        if (Date.now() - session.lastUpdateTime < 30 * 60 * 1000) {
          setViewSession(session);
          setHasStartedTracking(true);
          console.log('[VideoTracking] Recovered session:', session.sessionId);
        } else {
          // Session too old, remove it
          localStorage.removeItem(`view_session_${videoId}`);
        }
      } catch (error) {
        console.error('[VideoTracking] Failed to recover session:', error);
        localStorage.removeItem(`view_session_${videoId}`);
      }
    }
  }, [videoId, viewSession]);

  // Handle visibility change
  useEffect(() => {
    const handleVisibilityChange = () => {
      if (document.hidden && viewSession) {
        updateViewProgress(true);
      }
    };

    document.addEventListener('visibilitychange', handleVisibilityChange);
    return () => {
      document.removeEventListener('visibilitychange', handleVisibilityChange);
    };
  }, [viewSession, updateViewProgress]);

  return (
    <VideoPlayer
      src={src}
      poster={poster}
      title={title}
      isActive={isActive}
      autoplay={autoplay}
      volume={volume}
      onPlay={handlePlay}
      onPause={handlePause}
      onEnded={handleEnded}
      onTimeUpdate={handleTimeUpdate}
      className={className}
    />
  );
};

export default VideoPlayerWithTracking;