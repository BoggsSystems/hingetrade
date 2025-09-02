using CreatorStudio.Domain.Entities;
using CreatorStudio.Domain.Interfaces;
using CreatorStudio.Domain.Services;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Logging;

namespace CreatorStudio.Application.Services;

public class VideoViewTrackingService : IVideoViewTrackingService
{
    private readonly IRepository<VideoView> _viewRepository;
    private readonly IRepository<Video> _videoRepository;
    private readonly IMemoryCache _cache;
    private readonly ILogger<VideoViewTrackingService> _logger;

    // Cache keys
    private const string VIEW_COUNT_CACHE_PREFIX = "view_count_";
    private const string RATE_LIMIT_CACHE_PREFIX = "rate_limit_";
    private const int RATE_LIMIT_WINDOW_MINUTES = 60;
    private const int MAX_VIEWS_PER_HOUR = 10;

    public VideoViewTrackingService(
        IRepository<VideoView> viewRepository,
        IRepository<Video> videoRepository,
        IMemoryCache cache,
        ILogger<VideoViewTrackingService> logger)
    {
        _viewRepository = viewRepository;
        _videoRepository = videoRepository;
        _cache = cache;
        _logger = logger;
    }

    public async Task<Guid> StartViewSessionAsync(
        Guid videoId, 
        Guid? userId = null, 
        string? anonymousId = null,
        string? ipAddress = null,
        string? userAgent = null,
        CancellationToken cancellationToken = default)
    {
        // Generate session ID
        var sessionId = Guid.NewGuid();
        
        _logger.LogDebug("Starting view session {SessionId} for video {VideoId}", sessionId, videoId);

        // Cache the session for quick lookups
        _cache.Set($"session_{sessionId}", new ViewSession
        {
            SessionId = sessionId,
            VideoId = videoId,
            UserId = userId,
            AnonymousId = anonymousId,
            StartedAt = DateTime.UtcNow,
            LastUpdatedAt = DateTime.UtcNow
        }, TimeSpan.FromMinutes(30));

        return sessionId;
    }

    public async Task<bool> UpdateViewProgressAsync(
        Guid sessionId,
        double watchTimeSeconds,
        double maxWatchTimeSeconds,
        CancellationToken cancellationToken = default)
    {
        // Get session from cache
        if (!_cache.TryGetValue($"session_{sessionId}", out ViewSession? session))
        {
            _logger.LogWarning("Session {SessionId} not found in cache", sessionId);
            return false;
        }

        // Update session
        session.LastUpdatedAt = DateTime.UtcNow;
        session.CurrentWatchTime = watchTimeSeconds;
        session.MaxWatchTime = Math.Max(session.MaxWatchTime, maxWatchTimeSeconds);

        // Update cache
        _cache.Set($"session_{sessionId}", session, TimeSpan.FromMinutes(30));

        return true;
    }

    public async Task<bool> CompleteViewSessionAsync(
        Guid sessionId,
        double finalWatchTimeSeconds,
        bool completed,
        CancellationToken cancellationToken = default)
    {
        // Get and remove session from cache
        if (!_cache.TryGetValue($"session_{sessionId}", out ViewSession? session))
        {
            _logger.LogWarning("Session {SessionId} not found in cache", sessionId);
            return false;
        }

        _cache.Remove($"session_{sessionId}");

        _logger.LogInformation("Completed view session {SessionId} for video {VideoId}. Duration: {Duration}s",
            sessionId, session.VideoId, finalWatchTimeSeconds);

        return true;
    }

    public async Task<bool> RecordViewEngagementAsync(
        Guid sessionId,
        bool liked,
        bool? shared = null,
        CancellationToken cancellationToken = default)
    {
        _logger.LogDebug("Recording engagement for session {SessionId}: Liked={Liked}, Shared={Shared}",
            sessionId, liked, shared);
        return true;
    }

    public async Task<VideoViewStats> GetVideoViewStatsAsync(
        Guid videoId,
        CancellationToken cancellationToken = default)
    {
        // Try cache first
        var cacheKey = $"{VIEW_COUNT_CACHE_PREFIX}{videoId}";
        if (_cache.TryGetValue(cacheKey, out VideoViewStats? cachedStats))
        {
            return cachedStats;
        }

        // Get from database
        var views = await _viewRepository.FindAsync(
            v => v.VideoId == videoId,
            cancellationToken);

        var stats = new VideoViewStats
        {
            TotalViews = views.Count(),
            UniqueViews = views.Select(v => v.UserId ?? Guid.Parse(v.AnonymousId ?? Guid.Empty.ToString())).Distinct().Count(),
            AverageWatchTimeSeconds = views.Any() ? views.Average(v => v.WatchTimeSeconds) : 0,
            AverageCompletionRate = views.Any() ? (double)views.Average(v => v.WatchPercentage) : 0,
            Likes = views.Count(v => v.Liked),
            Shares = views.Count(v => v.Shared),
            LastViewedAt = views.Any() ? views.Max(v => v.LastWatchedAt) : null
        };

        stats.EngagementRate = stats.TotalViews > 0 
            ? (double)(stats.Likes + stats.Shares) / stats.TotalViews 
            : 0;

        // Cache for 5 minutes
        _cache.Set(cacheKey, stats, TimeSpan.FromMinutes(5));

        return stats;
    }

    public async Task<bool> ValidateViewSessionAsync(
        Guid videoId,
        string? ipAddress,
        string? userAgent,
        Guid? userId = null,
        CancellationToken cancellationToken = default)
    {
        // Basic validation
        if (string.IsNullOrEmpty(ipAddress))
        {
            _logger.LogWarning("No IP address provided for view validation");
            return false;
        }

        // Check for bot user agents
        if (!string.IsNullOrEmpty(userAgent))
        {
            var botPatterns = new[] { "bot", "crawler", "spider", "scraper", "curl", "wget" };
            var lowerUserAgent = userAgent.ToLower();
            if (botPatterns.Any(pattern => lowerUserAgent.Contains(pattern)))
            {
                _logger.LogWarning("Bot detected in user agent: {UserAgent}", userAgent);
                return false;
            }
        }

        // Rate limiting per IP
        var rateLimitKey = $"{RATE_LIMIT_CACHE_PREFIX}{videoId}_{ipAddress}";
        var viewCount = _cache.Get<int>(rateLimitKey);
        
        if (viewCount >= MAX_VIEWS_PER_HOUR)
        {
            _logger.LogWarning("Rate limit exceeded for video {VideoId} from IP {IpAddress}", videoId, ipAddress);
            return false;
        }

        // Increment view count for rate limiting
        _cache.Set(rateLimitKey, viewCount + 1, TimeSpan.FromMinutes(RATE_LIMIT_WINDOW_MINUTES));

        return true;
    }

    // Internal session tracking class
    private class ViewSession
    {
        public Guid SessionId { get; set; }
        public Guid VideoId { get; set; }
        public Guid? UserId { get; set; }
        public string? AnonymousId { get; set; }
        public DateTime StartedAt { get; set; }
        public DateTime LastUpdatedAt { get; set; }
        public double CurrentWatchTime { get; set; }
        public double MaxWatchTime { get; set; }
    }
}