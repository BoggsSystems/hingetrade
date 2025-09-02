import React, { useState, useEffect, useRef, useCallback } from 'react';
import type { IPanelComponentProps } from '../../types/panel';
import type { PanelConfig } from '../../types/layout';
import VideoPlayerWithTracking from './VideoPlayerWithTracking';
import './VideoPanel.css';

// Video data types
interface VideoDto {
  id: string;
  creatorId: string;
  title: string;
  description?: string;
  thumbnailUrl?: string;
  videoUrl?: string;
  status: number;
  visibility: number;
  durationSeconds?: number;
  fileSizeBytes?: number;
  tags?: string[];
  tradingSymbols?: string[];
  hasTranscription?: boolean;
  createdAt: string;
  publishedAt?: string;
  scheduledAt?: string;
  isSubscriberOnly: boolean;
  minimumSubscriptionTier?: number;
  purchasePrice?: number;
  viewCount: number;
  averageWatchTime: number;
  engagementRate: number;
  creatorDisplayName: string;
  creatorProfileImageUrl?: string;
  isFromFollowedCreator?: boolean;
  userSubscriptionTier?: number;
  trendingScore?: number;
  isPublished?: boolean;
  durationFormatted?: string;
  fileSizeFormatted?: string;
  // Legacy fields for compatibility with existing UI
  mentionedSymbols?: string[];
  realTimePrices?: Record<string, number>;
  tradingSignals?: any[];
}

interface VideoFeedResponse {
  videos: VideoDto[];
  total: number;
  page: number;
  pageSize: number;
  hasMore: boolean;
}

interface VideoPanelConfig extends PanelConfig {
  feedType?: 'personalized' | 'trending' | 'following' | 'symbol';
  autoplay?: boolean;
  showTradingOverlays?: boolean;
  volume?: number;
}

interface VideoPanelProps extends IPanelComponentProps {
  config: VideoPanelConfig;
}

export const VideoPanel: React.FC<VideoPanelProps> = ({
  config,
  symbol: propSymbol,
  onSymbolChange,
  onConfigChange
}) => {
  const [videos, setVideos] = useState<VideoDto[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [currentVideoIndex, setCurrentVideoIndex] = useState(0);
  const [page, setPage] = useState(1);
  const [hasMore, setHasMore] = useState(true);
  
  const containerRef = useRef<HTMLDivElement>(null);
  
  const feedType = config.feedType || 'personalized';
  const autoplay = config.autoplay ?? true;
  const showTradingOverlays = config.showTradingOverlays ?? true;
  const symbol = propSymbol || config.symbol;

  // Fetch videos from API
  const fetchVideos = useCallback(async (pageNum: number = 1, feedType: string = 'personalized') => {
    console.log(`[VideoPanel] 🎬 Fetching videos - Page: ${pageNum}, FeedType: ${feedType}, Symbol: ${symbol}`);
    
    try {
      setLoading(true);
      setError(null);
      
      // Use Creator Studio API endpoints for public video content
      const baseUrl = 'http://localhost:5155';
      let url = `${baseUrl}/api/videos/public/feed?page=${pageNum}&pageSize=20&feedType=${feedType}`;
      
      if (symbol && feedType === 'symbol') {
        url = `${baseUrl}/api/videos/public/symbol/${symbol}?page=${pageNum}&pageSize=20&sortBy=newest`;
      } else if (feedType === 'trending') {
        url = `${baseUrl}/api/videos/public/trending?page=${pageNum}&pageSize=20&hours=24`;
      } else if (feedType === 'following') {
        // For following feed, we need user ID - fallback to personalized for now
        const token = localStorage.getItem('token');
        if (token) {
          // TODO: Extract user ID from token or user context
          url = `${baseUrl}/api/videos/public/feed?page=${pageNum}&pageSize=20&feedType=personalized`;
        }
      }

      console.log(`[VideoPanel] 📡 Making request to: ${url}`);

      // Public endpoints don't require authentication
      const response = await fetch(url, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json'
        }
      });

      console.log(`[VideoPanel] 📨 Response status: ${response.status} ${response.statusText}`);
      console.log(`[VideoPanel] 📝 Response headers:`, response.headers);

      if (!response.ok) {
        const errorText = await response.text();
        console.error(`[VideoPanel] ❌ Error response body:`, errorText);
        throw new Error(`Failed to fetch videos: ${response.status} ${response.statusText} - ${errorText.substring(0, 200)}`);
      }

      // Log the raw response text to see what we're actually getting
      const responseText = await response.text();
      console.log(`[VideoPanel] 📄 Raw response (first 500 chars):`, responseText.substring(0, 500));
      
      // Try to parse as JSON
      let data: VideoFeedResponse;
      try {
        data = JSON.parse(responseText);
        console.log(`[VideoPanel] ✅ Successfully parsed JSON:`, data);
      } catch (parseError) {
        console.error(`[VideoPanel] ❌ JSON Parse Error:`, parseError);
        console.error(`[VideoPanel] 📄 Full response:`, responseText);
        
        // Check if it's an HTML error page (likely server not running)
        if (responseText.trim().startsWith('<!')) {
          console.warn(`[VideoPanel] 🚨 Received HTML instead of JSON - Creator Studio API server may not be running`);
          throw new Error(`Creator Studio API server appears to be down or not configured. Expected JSON but received HTML page.`);
        }
        
        throw new Error(`Invalid JSON response: ${parseError instanceof Error ? parseError.message : 'Unknown parsing error'}`);
      }
      
      if (pageNum === 1) {
        console.log(`[VideoPanel] 🔄 Setting ${data.videos.length} videos (page 1)`);
        setVideos(data.videos);
        setCurrentVideoIndex(0);
      } else {
        console.log(`[VideoPanel] ➕ Adding ${data.videos.length} more videos (page ${pageNum})`);
        setVideos(prev => [...prev, ...data.videos]);
      }
      
      setHasMore(data.hasMore);
      setPage(pageNum);
      console.log(`[VideoPanel] ✅ Fetch complete - Total videos: ${pageNum === 1 ? data.videos.length : 'previous + ' + data.videos.length}, HasMore: ${data.hasMore}`);
      
    } catch (err) {
      console.error('[VideoPanel] ❌ Fetch error:', err);
      
      // For development - provide mock data if API is not available
      if (err instanceof Error && err.message.includes('Creator Studio API server appears to be down')) {
        console.log('[VideoPanel] 🔧 Using mock data for development');
        const mockData: VideoFeedResponse = {
          videos: [
            {
              id: 'mock-1',
              creatorId: 'creator-1',
              title: 'TSLA Breaking Out! 🚀',
              description: 'Tesla showing strong momentum after earnings beat. Key levels to watch.',
              thumbnailUrl: 'https://via.placeholder.com/400x600/1a1a1a/ffffff?text=TSLA+Video',
              videoUrl: undefined, // No actual video for mock
              status: 5, // Published status
              visibility: 2, // Public visibility
              durationSeconds: 45,
              fileSizeBytes: 15000000,
              tags: ['tesla', 'earnings', 'breakout'],
              tradingSymbols: ['TSLA', 'NVDA'],
              hasTranscription: false,
              createdAt: new Date().toISOString(),
              publishedAt: new Date().toISOString(),
              isSubscriberOnly: false,
              minimumSubscriptionTier: 0,
              viewCount: 12500,
              averageWatchTime: 38,
              engagementRate: 0.085,
              creatorDisplayName: 'TechTrader Pro',
              creatorProfileImageUrl: 'https://via.placeholder.com/40x40/4caf50/ffffff?text=TT',
              isFromFollowedCreator: false,
              isPublished: true,
              durationFormatted: '0:45',
              fileSizeFormatted: '14.3 MB',
              // Legacy compatibility
              mentionedSymbols: ['TSLA', 'NVDA'],
              realTimePrices: { 'TSLA': 234.56, 'NVDA': 489.12 },
              tradingSignals: []
            },
            {
              id: 'mock-2', 
              creatorId: 'creator-2',
              title: 'AAPL vs MSFT: Which to Buy? 🤔',
              description: 'Comparing the tech giants. My analysis on which offers better value.',
              thumbnailUrl: 'https://via.placeholder.com/400x600/1a1a1a/ffffff?text=AAPL+vs+MSFT',
              videoUrl: undefined,
              status: 5,
              visibility: 2,
              durationSeconds: 72,
              fileSizeBytes: 22000000,
              tags: ['apple', 'microsoft', 'comparison'],
              tradingSymbols: ['AAPL', 'MSFT'],
              hasTranscription: false,
              createdAt: new Date(Date.now() - 3600000).toISOString(),
              publishedAt: new Date(Date.now() - 3600000).toISOString(),
              isSubscriberOnly: false,
              minimumSubscriptionTier: 0,
              viewCount: 8320,
              averageWatchTime: 58,
              engagementRate: 0.092,
              creatorDisplayName: 'MarketMaven',
              creatorProfileImageUrl: 'https://via.placeholder.com/40x40/2196f3/ffffff?text=MM',
              isFromFollowedCreator: false,
              isPublished: true,
              durationFormatted: '1:12',
              fileSizeFormatted: '21.0 MB',
              mentionedSymbols: ['AAPL', 'MSFT'],
              realTimePrices: { 'AAPL': 178.23, 'MSFT': 342.87 },
              tradingSignals: []
            },
            {
              id: 'mock-3',
              creatorId: 'creator-3', 
              title: 'Market Crash Coming? 📉',
              description: 'Warning signs I\'m seeing in the market. How to protect your portfolio.',
              thumbnailUrl: 'https://via.placeholder.com/400x600/1a1a1a/ffffff?text=Market+Warning',
              videoUrl: undefined,
              status: 5,
              visibility: 2,
              durationSeconds: 126,
              fileSizeBytes: 38000000,
              tags: ['market', 'crash', 'portfolio', 'protection'],
              tradingSymbols: ['SPY', 'QQQ', 'VIX'],
              hasTranscription: false,
              createdAt: new Date(Date.now() - 7200000).toISOString(),
              publishedAt: new Date(Date.now() - 7200000).toISOString(),
              isSubscriberOnly: true,
              minimumSubscriptionTier: 1,
              viewCount: 25600,
              averageWatchTime: 98,
              engagementRate: 0.156,
              creatorDisplayName: 'BearishBob',
              creatorProfileImageUrl: 'https://via.placeholder.com/40x40/f44336/ffffff?text=BB',
              isFromFollowedCreator: false,
              isPublished: true,
              durationFormatted: '2:06',
              fileSizeFormatted: '36.2 MB',
              mentionedSymbols: ['SPY', 'QQQ', 'VIX'],
              realTimePrices: { 'SPY': 445.67, 'QQQ': 378.91, 'VIX': 18.42 },
              tradingSignals: []
            }
          ],
          total: 3,
          page: pageNum,
          pageSize: 20,
          hasMore: false
        };

        if (pageNum === 1) {
          setVideos(mockData.videos);
          setCurrentVideoIndex(0);
        }
        setHasMore(mockData.hasMore);
        setPage(pageNum);
        console.log(`[VideoPanel] ✅ Mock data loaded - ${mockData.videos.length} videos`);
      } else {
        setError(err instanceof Error ? err.message : 'Failed to load videos');
      }
    } finally {
      setLoading(false);
    }
  }, [symbol]);

  // Load more videos when reaching the end
  const loadMoreVideos = useCallback(() => {
    if (!loading && hasMore) {
      fetchVideos(page + 1, feedType);
    }
  }, [loading, hasMore, page, feedType, fetchVideos]);

  // Load more videos when near the end (since we only show one at a time)
  useEffect(() => {
    if (currentVideoIndex >= videos.length - 3) {
      loadMoreVideos();
    }
  }, [currentVideoIndex, videos.length, loadMoreVideos]);

  // Initial load
  useEffect(() => {
    fetchVideos(1, feedType);
  }, [fetchVideos, feedType]);

  // Handle symbol changes
  useEffect(() => {
    if (propSymbol && propSymbol !== config.symbol) {
      if (feedType === 'symbol') {
        fetchVideos(1, 'symbol');
      }
    }
  }, [propSymbol, config.symbol, feedType, fetchVideos]);

  // Handle video symbol click
  const handleSymbolClick = (clickedSymbol: string) => {
    if (onSymbolChange) {
      onSymbolChange(clickedSymbol);
    }
  };

  // Handle feed type change
  const handleFeedTypeChange = (newFeedType: string) => {
    if (onConfigChange) {
      onConfigChange({ settings: { feedType: newFeedType } });
    }
    fetchVideos(1, newFeedType);
  };

  // Handle video interaction
  // Navigation handlers for TikTok-style up/down arrows
  const navigateUp = useCallback(() => {
    if (currentVideoIndex > 0) {
      const newIndex = currentVideoIndex - 1;
      setCurrentVideoIndex(newIndex);
    }
  }, [currentVideoIndex]);

  const navigateDown = useCallback(() => {
    if (currentVideoIndex < videos.length - 1) {
      const newIndex = currentVideoIndex + 1;
      setCurrentVideoIndex(newIndex);
    }
  }, [currentVideoIndex, videos.length]);

  const handleVideoInteraction = async (videoId: string, interactionType: string, value: boolean) => {
    try {
      const token = localStorage.getItem('token');
      if (!token) {
        console.log('[VideoPanel] 🔒 No auth token - skipping interaction recording');
        return;
      }

      // Use Trading API for user interactions (requires authentication)
      const response = await fetch(`http://localhost:5001/api/videos/${videoId}/interactions`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({
          type: interactionType.toLowerCase(),
          value,
          watchDurationSeconds: 0 // Could be enhanced to track actual watch time
        })
      });

      if (!response.ok) {
        console.error('Failed to record interaction:', response.status, response.statusText);
      } else {
        console.log(`[VideoPanel] ✅ Recorded ${interactionType} interaction for video ${videoId}`);
      }
    } catch (err) {
      console.error('Error recording interaction:', err);
    }
  };

  if (loading && videos.length === 0) {
    return (
      <div className="video-panel">
        <div className="video-panel-header">
          <h3>Videos</h3>
          <div className="feed-selector">
            <select
              value={feedType}
              onChange={(e) => handleFeedTypeChange(e.target.value)}
              className="feed-select"
            >
              <option value="personalized">For You</option>
              <option value="trending">Trending</option>
              <option value="following">Following</option>
              {symbol && <option value="symbol">{symbol}</option>}
            </select>
          </div>
        </div>
        <div className="video-panel-loading">
          <div className="spinner"></div>
          <p>Loading videos...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="video-panel">
        <div className="video-panel-header">
          <h3>Videos</h3>
        </div>
        <div className="video-panel-error">
          <p>⚠️ {error}</p>
          <button onClick={() => fetchVideos(1, feedType)}>Retry</button>
        </div>
      </div>
    );
  }

  return (
    <div className="video-panel" ref={containerRef}>
      <div className="video-panel-header">
        <h3>Videos</h3>
        <div className="feed-selector">
          <select
            value={feedType}
            onChange={(e) => handleFeedTypeChange(e.target.value)}
            className="feed-select"
          >
            <option value="personalized">For You</option>
            <option value="trending">Trending</option>
            <option value="following">Following</option>
            {symbol && <option value="symbol">{symbol}</option>}
          </select>
        </div>
      </div>

      <div className="video-feed">
        {videos.length > 0 && videos[currentVideoIndex] && (
          <VideoItem
            key={videos[currentVideoIndex].id}
            video={videos[currentVideoIndex]}
            index={currentVideoIndex}
            isActive={true}
            autoplay={autoplay}
            showTradingOverlays={showTradingOverlays}
            onSymbolClick={handleSymbolClick}
            onInteraction={handleVideoInteraction}
          />
        )}
        
        {loading && videos.length > 0 && (
          <div className="video-loading-more">
            <div className="spinner"></div>
          </div>
        )}

        {/* TikTok-style navigation arrows */}
        {videos.length > 0 && (
          <div className="video-navigation-arrows">
            {currentVideoIndex > 0 && (
              <button 
                className="nav-arrow nav-arrow-up"
                onClick={navigateUp}
                title="Previous video"
              >
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
                  <path d="M7 14L12 9L17 14" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                </svg>
              </button>
            )}
            
            {currentVideoIndex < videos.length - 1 && (
              <button 
                className="nav-arrow nav-arrow-down"
                onClick={navigateDown}
                title="Next video"
              >
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
                  <path d="M7 10L12 15L17 10" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                </svg>
              </button>
            )}
          </div>
        )}
      </div>
    </div>
  );
};

// Individual video item component
interface VideoItemProps {
  video: VideoDto;
  index: number;
  isActive: boolean;
  autoplay: boolean;
  showTradingOverlays: boolean;
  onSymbolClick: (symbol: string) => void;
  onInteraction: (videoId: string, type: string, value: boolean) => void;
}

const VideoItem: React.FC<VideoItemProps> = ({
  video,
  index,
  isActive,
  autoplay,
  showTradingOverlays,
  onSymbolClick,
  onInteraction
}) => {
  const itemRef = useRef<HTMLDivElement>(null);
  const [liked, setLiked] = useState(false);
  const [saved, setSaved] = useState(false);


  const handleLike = () => {
    const newLiked = !liked;
    setLiked(newLiked);
    onInteraction(video.id, 'Like', newLiked);
  };

  const handleSave = () => {
    const newSaved = !saved;
    setSaved(newSaved);
    onInteraction(video.id, 'Save', newSaved);
  };

  const formatDuration = (seconds?: number) => {
    if (!seconds) return '0:00';
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  const formatNumber = (num: number) => {
    if (num >= 1000000) return `${(num / 1000000).toFixed(1)}M`;
    if (num >= 1000) return `${(num / 1000).toFixed(1)}K`;
    return num.toString();
  };

  return (
    <div
      ref={itemRef}
      data-video-index={index}
      className={`video-item ${isActive ? 'active' : ''}`}
    >
      <div className="video-content">
        <VideoPlayerWithTracking
          videoId={video.id}
          src={video.videoUrl}
          poster={video.thumbnailUrl}
          title={video.title}
          isActive={isActive}
          autoplay={autoplay}
          volume={0.5}
          duration={video.durationSeconds}
          onPlay={() => {}}
          onPause={() => {}}
          className="video-player"
          apiBaseUrl="http://localhost:5155/api"
        />

        {showTradingOverlays && (video.tradingSymbols || video.mentionedSymbols) && (video.tradingSymbols || video.mentionedSymbols)!.length > 0 && (
          <div className="trading-overlays">
            <div className="symbol-chips">
              {(video.tradingSymbols || video.mentionedSymbols || []).slice(0, 3).map((symbol) => (
                <button
                  key={symbol}
                  className="symbol-chip"
                  onClick={() => onSymbolClick(symbol)}
                >
                  <span className="symbol">{symbol}</span>
                  {video.realTimePrices?.[symbol] && (
                    <span className="price">${video.realTimePrices[symbol].toFixed(2)}</span>
                  )}
                </button>
              ))}
            </div>
          </div>
        )}

        <div className="video-info">
          <div className="creator-info">
            <div className="creator-avatar">
              {video.creatorProfileImageUrl ? (
                <img src={video.creatorProfileImageUrl} alt={video.creatorDisplayName} />
              ) : (
                <div className="avatar-placeholder">👤</div>
              )}
            </div>
            <div className="creator-details">
              <span className="creator-name">{video.creatorDisplayName}</span>
              <span className="video-meta">
                {formatNumber(video.viewCount)} views • {formatDuration(video.durationSeconds)}
              </span>
            </div>
          </div>

          <div className="video-description">
            <h4>{video.title}</h4>
            {video.description && (
              <p className="description-text">
                {video.description.length > 100
                  ? `${video.description.substring(0, 100)}...`
                  : video.description
                }
              </p>
            )}
            {video.tags && video.tags.length > 0 && (
              <div className="video-tags">
                {video.tags.slice(0, 3).map((tag) => (
                  <span key={tag} className="tag">#{tag}</span>
                ))}
              </div>
            )}
          </div>
        </div>

        <div className="video-actions">
          <button
            className={`action-btn like-btn ${liked ? 'active' : ''}`}
            onClick={handleLike}
          >
            {liked ? '❤️' : '🤍'}
            <span>{formatNumber(Math.floor(video.viewCount * video.engagementRate))}</span>
          </button>
          
          <button
            className={`action-btn save-btn ${saved ? 'active' : ''}`}
            onClick={handleSave}
          >
            {saved ? '📌' : '🔖'}
            <span>Save</span>
          </button>
          
          <button className="action-btn share-btn">
            🔗
            <span>Share</span>
          </button>
        </div>
      </div>
    </div>
  );
};

// Add static properties for panel registration
(VideoPanel as any).panelType = 'video';
(VideoPanel as any).displayName = 'Video Feed';
(VideoPanel as any).defaultConfig = {
  feedType: 'personalized',
  autoplay: true,
  showTradingOverlays: true,
  volume: 0.5
};

export default VideoPanel;