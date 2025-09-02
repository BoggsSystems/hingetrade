import React, { useState, useRef, useEffect } from 'react';
import './VideoPlayer.css';

interface VideoPlayerProps {
  src?: string;
  poster?: string;
  title: string;
  isActive: boolean;
  autoplay: boolean;
  volume: number;
  onPlay?: () => void;
  onPause?: () => void;
  onEnded?: () => void;
  onTimeUpdate?: (currentTime: number, duration: number) => void;
  className?: string;
}

export const VideoPlayer: React.FC<VideoPlayerProps> = ({
  src,
  poster,
  title,
  isActive,
  autoplay,
  volume,
  onPlay,
  onPause,
  onEnded,
  onTimeUpdate,
  className = ''
}) => {
  const videoRef = useRef<HTMLVideoElement>(null);
  const progressRef = useRef<HTMLDivElement>(null);
  const [isPlaying, setIsPlaying] = useState(false);
  const [currentTime, setCurrentTime] = useState(0);
  const [duration, setDuration] = useState(0);
  // Controls are always shown in this implementation
  // const [showControls] = useState(true);
  const [isMuted, setIsMuted] = useState(true);
  const [currentVolume, setCurrentVolume] = useState(volume);
  const [showPlayPause, setShowPlayPause] = useState(false);
  const [bufferedProgress, setBufferedProgress] = useState(0);
  const [showSoundIndicator, setShowSoundIndicator] = useState(false);
  const [showVolumeSlider, setShowVolumeSlider] = useState(false);
  const playPauseTimeoutRef = useRef<number | null>(null);
  const soundIndicatorTimeoutRef = useRef<number | null>(null);
  const volumeTimeoutRef = useRef<number | null>(null);
  const volumeSliderRef = useRef<HTMLDivElement>(null);

  // Handle autoplay when video becomes active
  useEffect(() => {
    const video = videoRef.current;
    if (!video || !src) return;

    if (isActive && autoplay) {
      const playPromise = video.play();
      if (playPromise) {
        playPromise.then(() => {
          setIsPlaying(true);
        }).catch((error) => {
          console.error('Auto-play failed:', error);
        });
      }
    } else {
      video.pause();
      setIsPlaying(false);
    }
  }, [isActive, autoplay, src]);

  // Set volume
  useEffect(() => {
    const video = videoRef.current;
    if (video) {
      video.volume = isMuted ? 0 : currentVolume;
    }
  }, [currentVolume, isMuted]);

  // Video event handlers
  const handlePlay = () => {
    setIsPlaying(true);
    onPlay?.();
  };

  const handlePause = () => {
    setIsPlaying(false);
    onPause?.();
  };

  const handleEnded = () => {
    setIsPlaying(false);
    onEnded?.();
  };

  const handleTimeUpdate = () => {
    const video = videoRef.current;
    if (!video) return;

    const current = video.currentTime;
    const total = video.duration;

    setCurrentTime(current);
    setDuration(total);
    onTimeUpdate?.(current, total);

    // Update buffered progress
    if (video.buffered.length > 0) {
      const buffered = video.buffered.end(video.buffered.length - 1);
      setBufferedProgress((buffered / total) * 100);
    }
  };

  const handleLoadedMetadata = () => {
    const video = videoRef.current;
    if (video) {
      setDuration(video.duration);
    }
  };

  // TikTok-style play/pause with visual feedback
  const togglePlay = () => {
    const video = videoRef.current;
    if (!video) return;

    if (isPlaying) {
      video.pause();
    } else {
      video.play();
    }

    // Show play/pause feedback
    setShowPlayPause(true);
    if (playPauseTimeoutRef.current) {
      clearTimeout(playPauseTimeoutRef.current);
    }
    playPauseTimeoutRef.current = setTimeout(() => {
      setShowPlayPause(false);
    }, 600);
  };

  const handleProgressClick = (e: React.MouseEvent<HTMLDivElement>) => {
    const video = videoRef.current;
    const progressBar = progressRef.current;
    if (!video || !progressBar) return;

    const rect = progressBar.getBoundingClientRect();
    const clickX = e.clientX - rect.left;
    const clickRatio = clickX / rect.width;
    const newTime = clickRatio * duration;

    video.currentTime = newTime;
    setCurrentTime(newTime);
  };

  // TikTok-style volume icon click
  const handleVolumeClick = (e: React.MouseEvent) => {
    e.stopPropagation();
    
    if (isMuted) {
      setIsMuted(false);
    } else {
      // Show volume slider
      setShowVolumeSlider(true);
      if (volumeTimeoutRef.current) {
        clearTimeout(volumeTimeoutRef.current);
      }
      volumeTimeoutRef.current = setTimeout(() => {
        setShowVolumeSlider(false);
      }, 3000);
    }
    
    // Show sound indicator
    setShowSoundIndicator(true);
    if (soundIndicatorTimeoutRef.current) {
      clearTimeout(soundIndicatorTimeoutRef.current);
    }
    soundIndicatorTimeoutRef.current = setTimeout(() => {
      setShowSoundIndicator(false);
    }, 1500);
  };

  // TikTok-style mute toggle with double-tap
  const toggleMute = (e?: React.MouseEvent) => {
    e?.stopPropagation();
    setIsMuted(!isMuted);
    
    // Show sound indicator
    setShowSoundIndicator(true);
    if (soundIndicatorTimeoutRef.current) {
      clearTimeout(soundIndicatorTimeoutRef.current);
    }
    soundIndicatorTimeoutRef.current = setTimeout(() => {
      setShowSoundIndicator(false);
    }, 2000);
  };

  // Handle volume slider interaction
  const handleVolumeSliderClick = (e: React.MouseEvent) => {
    e.stopPropagation();
    const slider = volumeSliderRef.current;
    if (!slider) return;

    const rect = slider.getBoundingClientRect();
    const clickY = e.clientY - rect.top;
    const clickRatio = 1 - (clickY / rect.height); // Invert because slider goes bottom to top
    const newVolume = Math.max(0, Math.min(1, clickRatio));

    setCurrentVolume(newVolume);
    if (newVolume > 0) {
      setIsMuted(false);
    }

    // Show sound indicator
    setShowSoundIndicator(true);
    if (soundIndicatorTimeoutRef.current) {
      clearTimeout(soundIndicatorTimeoutRef.current);
    }
    soundIndicatorTimeoutRef.current = setTimeout(() => {
      setShowSoundIndicator(false);
    }, 1000);
  };

  // Cleanup timeouts
  useEffect(() => {
    return () => {
      if (playPauseTimeoutRef.current) {
        clearTimeout(playPauseTimeoutRef.current);
      }
      if (soundIndicatorTimeoutRef.current) {
        clearTimeout(soundIndicatorTimeoutRef.current);
      }
      if (volumeTimeoutRef.current) {
        clearTimeout(volumeTimeoutRef.current);
      }
    };
  }, []);

  // Commented out unused function
  // const formatTime = (seconds: number): string => {
  //   if (isNaN(seconds)) return '0:00';
  //   
  //   const mins = Math.floor(seconds / 60);
  //   const secs = Math.floor(seconds % 60);
  //   return `${mins}:${secs.toString().padStart(2, '0')}`;
  // };

  const progressPercentage = duration > 0 ? (currentTime / duration) * 100 : 0;

  if (!src) {
    return (
      <div className={`video-player-container no-video ${className}`}>
        <div className="video-placeholder">
          {poster ? (
            <img src={poster} alt={title} className="poster-image" />
          ) : (
            <div className="no-thumbnail">📹</div>
          )}
          <div className="video-overlay">
            <div className="no-video-message">Video not available</div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className={`video-player-container ${className}`}>
      <video
        ref={videoRef}
        className="video-element"
        poster={poster}
        muted={isMuted}
        loop
        playsInline
        onPlay={handlePlay}
        onPause={handlePause}
        onEnded={handleEnded}
        onTimeUpdate={handleTimeUpdate}
        onLoadedMetadata={handleLoadedMetadata}
        onClick={togglePlay}
        onDoubleClick={toggleMute}
      >
        <source src={src} type="video/mp4" />
        Your browser does not support the video tag.
      </video>

      {/* TikTok-Style Minimal Controls */}
      <div className="video-controls visible">
        {/* Only Progress Bar */}
        <div 
          className="progress-container"
          ref={progressRef}
          onClick={handleProgressClick}
        >
          <div className="progress-buffered" style={{ width: `${bufferedProgress}%` }} />
          <div className="progress-played" style={{ width: `${progressPercentage}%` }} />
        </div>
      </div>

      {/* TikTok-Style Volume Control */}
      <div className="tiktok-volume-control">
        <button 
          className="volume-icon"
          onClick={handleVolumeClick}
        >
          {isMuted ? '🔇' : currentVolume > 0.5 ? '🔊' : '🔉'}
        </button>
        
        <div 
          ref={volumeSliderRef}
          className={`volume-slider-tiktok ${showVolumeSlider ? 'visible' : ''}`}
          onClick={handleVolumeSliderClick}
        >
          <div 
            className="volume-fill" 
            style={{ height: `${(isMuted ? 0 : currentVolume) * 100}%` }}
          />
          <div 
            className="volume-handle" 
            style={{ bottom: `${(isMuted ? 0 : currentVolume) * 100 - 6}%` }}
          />
        </div>
      </div>

      {/* Sound Indicator */}
      <div className={`sound-indicator ${showSoundIndicator ? 'visible' : ''}`}>
        {isMuted ? 'Muted' : `Volume ${Math.round((isMuted ? 0 : currentVolume) * 100)}%`}
      </div>

      {/* TikTok-Style Play/Pause Feedback */}
      {showPlayPause && (
        <div className={`center-play-overlay show play-pause-feedback`}>
          <div className="center-play-btn">
            {isPlaying ? (
              <div className="pause-indicator">
                <div className="pause-bar"></div>
                <div className="pause-bar"></div>
              </div>
            ) : (
              '▶'
            )}
          </div>
        </div>
      )}

      {/* Loading Indicator */}
      {!duration && src && (
        <div className="video-loading">
          <div className="loading-spinner"></div>
        </div>
      )}
    </div>
  );
};

export default VideoPlayer;