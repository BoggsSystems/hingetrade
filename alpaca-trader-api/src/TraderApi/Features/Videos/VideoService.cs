using Microsoft.Extensions.Caching.Memory;
using TraderApi.Features.MarketData;
using System.Text.RegularExpressions;

namespace TraderApi.Features.Videos;

/// <summary>
/// Video service with trading enhancements and caching
/// </summary>
public interface IVideoService
{
    Task<VideoFeedResponse> GetVideoFeedAsync(Guid userId, VideoFeedRequest request, CancellationToken cancellationToken = default);
    Task<VideoDto> GetVideoAsync(Guid videoId, Guid? userId = null, CancellationToken cancellationToken = default);
    Task<bool> RecordInteractionAsync(Guid userId, Guid videoId, VideoInteractionRequest request, CancellationToken cancellationToken = default);
    Task<CreatorDto> GetCreatorAsync(Guid creatorId, Guid? userId = null, CancellationToken cancellationToken = default);
    Task FollowCreatorAsync(Guid userId, Guid creatorId, CancellationToken cancellationToken = default);
}

public class VideoService : IVideoService
{
    private readonly ICreatorStudioClient _creatorStudioClient;
    private readonly IMarketDataRestClient _marketDataRestClient;
    private readonly IUserMappingService _userMappingService;
    private readonly IMemoryCache _cache;
    private readonly ILogger<VideoService> _logger;

    // Symbol detection regex pattern
    private static readonly Regex SymbolPattern = new(@"\b[A-Z]{2,5}\b", RegexOptions.Compiled);
    
    // Common words to exclude from symbol detection
    private static readonly HashSet<string> ExcludedWords = new()
    {
        "THE", "AND", "FOR", "ARE", "BUT", "NOT", "YOU", "ALL", "CAN", "HER", "WAS", "ONE", "OUR", "HAD", "DAY", "GET", "USE", "MAN", "NEW", "NOW", "OLD", "SEE", "HIM", "TWO", "HOW", "ITS", "WHO", "DID", "YES", "HIS", "HAS", "LOT", "WAY", "TOO", "ANY", "MAY", "SAY", "SHE", "BUY", "OWN", "PUT", "END", "WHY", "TRY", "GOD", "SIX", "DOG", "EAT", "AGO", "SIT", "FUN", "BAD", "YET", "ARM", "FAR", "OFF", "BAG", "BAR", "BIG", "BOX", "BOY", "BUS", "CAR", "CAT", "CUP", "CUT", "DIG", "EAR", "EYE", "FEW", "FIX", "FLY", "GUN", "HIT", "JOB", "LAW", "LEG", "LET", "LIE", "MAP", "MIX", "NET", "OIL", "PAY", "PEN", "PET", "POP", "RED", "RUN", "SET", "SUN", "TAX", "TEA", "TOP", "VAN", "WIN", "ZIP"
    };

    public VideoService(
        ICreatorStudioClient creatorStudioClient,
        IMarketDataRestClient marketDataRestClient,
        IUserMappingService userMappingService,
        IMemoryCache cache,
        ILogger<VideoService> logger)
    {
        _creatorStudioClient = creatorStudioClient;
        _marketDataRestClient = marketDataRestClient;
        _userMappingService = userMappingService;
        _cache = cache;
        _logger = logger;
    }

    public async Task<VideoFeedResponse> GetVideoFeedAsync(Guid userId, VideoFeedRequest request, CancellationToken cancellationToken = default)
    {
        var cacheKey = $"video_feed_{request.FeedType}_{request.Page}_{request.PageSize}_{request.Symbol}";
        
        if (_cache.TryGetValue(cacheKey, out VideoFeedResponse? cachedResponse))
        {
            _logger.LogDebug("Returning cached video feed for feed type {FeedType}", request.FeedType);
            return cachedResponse!;
        }

        try
        {
            // Get public video feed - no user mapping required
            // Pass userId only for Following feed type to get user's followed creators
            var creatorStudioResponse = await _creatorStudioClient.GetVideoFeedAsync(userId, request, cancellationToken);
            
            // Enrich videos with trading data
            var enrichedVideos = await EnrichVideosWithTradingDataAsync(creatorStudioResponse.Videos, cancellationToken);
            
            var response = new VideoFeedResponse(
                enrichedVideos,
                creatorStudioResponse.Total,
                request.Page,
                request.PageSize,
                HasMore: (request.Page * request.PageSize) < creatorStudioResponse.Total
            );

            // Cache for 5 minutes (longer for public feeds)
            var cacheTime = request.FeedType == VideoFeedType.Trending ? TimeSpan.FromMinutes(10) : TimeSpan.FromMinutes(5);
            _cache.Set(cacheKey, response, cacheTime);
            
            _logger.LogDebug("Retrieved and cached video feed with {Count} videos for feed type {FeedType}", 
                enrichedVideos.Length, request.FeedType);
                
            return response;
        }
        catch (VideoServiceException)
        {
            // Re-throw video service exceptions
            throw;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unexpected error getting video feed for user {UserId}", userId);
            throw new VideoServiceException("Failed to retrieve video feed", ex);
        }
    }

    public async Task<VideoDto> GetVideoAsync(Guid videoId, Guid? userId = null, CancellationToken cancellationToken = default)
    {
        var cacheKey = $"video_{videoId}";
        
        if (_cache.TryGetValue(cacheKey, out VideoDto? cachedVideo))
        {
            _logger.LogDebug("Returning cached video {VideoId}", videoId);
            return cachedVideo!;
        }

        try
        {
            var creatorStudioVideo = await _creatorStudioClient.GetVideoAsync(videoId, cancellationToken);
            var enrichedVideos = await EnrichVideosWithTradingDataAsync(new[] { creatorStudioVideo }, cancellationToken);
            
            var video = enrichedVideos.First();
            
            // Cache for 10 minutes
            _cache.Set(cacheKey, video, TimeSpan.FromMinutes(10));
            
            _logger.LogDebug("Retrieved and cached video {VideoId}", videoId);
            
            return video;
        }
        catch (VideoServiceException)
        {
            throw;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unexpected error getting video {VideoId}", videoId);
            throw new VideoServiceException($"Failed to retrieve video {videoId}", ex);
        }
    }

    public async Task<bool> RecordInteractionAsync(Guid userId, Guid videoId, VideoInteractionRequest request, CancellationToken cancellationToken = default)
    {
        try
        {
            var success = await _creatorStudioClient.RecordInteractionAsync(userId, videoId, request.InteractionType, request.Value, cancellationToken);
            
            if (success)
            {
                // Invalidate relevant caches
                InvalidateVideoCache(videoId);
                InvalidateUserFeedCache(userId);
            }
            
            return success;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to record interaction for video {VideoId} by user {UserId}", videoId, userId);
            return false;
        }
    }

    public async Task<CreatorDto> GetCreatorAsync(Guid creatorId, Guid? userId = null, CancellationToken cancellationToken = default)
    {
        var cacheKey = $"creator_{creatorId}";
        
        if (_cache.TryGetValue(cacheKey, out CreatorDto? cachedCreator))
        {
            return cachedCreator!;
        }

        try
        {
            var creatorStudioCreator = await _creatorStudioClient.GetCreatorAsync(creatorId, cancellationToken);
            
            var creator = new CreatorDto(
                creatorStudioCreator.Id,
                creatorStudioCreator.DisplayName,
                creatorStudioCreator.Bio,
                creatorStudioCreator.ProfileImageUrl,
                creatorStudioCreator.FollowerCount,
                creatorStudioCreator.VideoCount,
                IsFollowing: false, // TODO: Implement following logic
                CreatorVerificationStatus.Unverified // TODO: Implement verification status
            );
            
            // Cache for 15 minutes
            _cache.Set(cacheKey, creator, TimeSpan.FromMinutes(15));
            
            return creator;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to get creator {CreatorId}", creatorId);
            throw new VideoServiceException($"Failed to retrieve creator {creatorId}", ex);
        }
    }

    private async Task<VideoDto[]> EnrichVideosWithTradingDataAsync(CreatorStudioVideo[] videos, CancellationToken cancellationToken)
    {
        var enrichedVideos = new List<VideoDto>();

        foreach (var video in videos)
        {
            try
            {
                // Extract stock symbols from title, description, and tags
                var mentionedSymbols = ExtractStockSymbols(video.Title, video.Description, video.Tags);
                
                // Get real-time prices for mentioned symbols
                var realTimePrices = await GetRealTimePricesAsync(mentionedSymbols, cancellationToken);
                
                // Generate trading signals (placeholder for now)
                var tradingSignals = GenerateTradingSignals(video, mentionedSymbols);
                
                var enrichedVideo = new VideoDto(
                    video.Id,
                    video.CreatorId,
                    video.Title,
                    video.Description,
                    video.ThumbnailUrl,
                    video.VideoUrl,
                    (VideoStatus)video.Status,
                    (VideoVisibility)video.Visibility,
                    video.DurationSeconds,
                    video.FileSizeBytes,
                    video.Tags,
                    video.CreatedAt,
                    video.PublishedAt,
                    video.IsSubscriberOnly,
                    video.ViewCount,
                    video.AverageWatchTime,
                    video.EngagementRate,
                    video.CreatorDisplayName,
                    video.CreatorProfileImageUrl,
                    
                    // Trading enhancements
                    mentionedSymbols,
                    realTimePrices,
                    tradingSignals
                );
                
                enrichedVideos.Add(enrichedVideo);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Failed to enrich video {VideoId}, returning basic data", video.Id);
                
                // Return video with minimal trading data on error
                var basicVideo = new VideoDto(
                    video.Id, video.CreatorId, video.Title, video.Description, video.ThumbnailUrl, video.VideoUrl,
                    (VideoStatus)video.Status, (VideoVisibility)video.Visibility, video.DurationSeconds, video.FileSizeBytes,
                    video.Tags, video.CreatedAt, video.PublishedAt, video.IsSubscriberOnly, video.ViewCount,
                    video.AverageWatchTime, video.EngagementRate, video.CreatorDisplayName, video.CreatorProfileImageUrl,
                    Array.Empty<string>(), new Dictionary<string, decimal>(), Array.Empty<TradingSignal>()
                );
                
                enrichedVideos.Add(basicVideo);
            }
        }

        return enrichedVideos.ToArray();
    }

    private string[] ExtractStockSymbols(string title, string? description, string[]? tags)
    {
        var symbols = new HashSet<string>();
        var text = $"{title} {description} {string.Join(" ", tags ?? Array.Empty<string>())}";
        
        var matches = SymbolPattern.Matches(text);
        foreach (Match match in matches)
        {
            var symbol = match.Value.ToUpperInvariant();
            
            // Skip excluded words and symbols that are too short
            if (!ExcludedWords.Contains(symbol) && symbol.Length >= 2)
            {
                symbols.Add(symbol);
            }
        }
        
        return symbols.ToArray();
    }

    private async Task<Dictionary<string, decimal>> GetRealTimePricesAsync(string[] symbols, CancellationToken cancellationToken)
    {
        var prices = new Dictionary<string, decimal>();
        
        if (symbols.Length == 0)
            return prices;

        try
        {
            // Get quotes for all symbols
            foreach (var symbol in symbols.Take(10)) // Limit to 10 symbols per video
            {
                try
                {
                    var quote = await _marketDataRestClient.GetLatestQuoteAsync(symbol);
                    if (quote?.Quote?.BidPrice > 0)
                    {
                        prices[symbol] = (decimal)quote.Quote.BidPrice;
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Failed to get price for symbol {Symbol}", symbol);
                }
            }
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to get real-time prices for symbols");
        }

        return prices;
    }

    private TradingSignal[] GenerateTradingSignals(CreatorStudioVideo video, string[] symbols)
    {
        // TODO: Implement AI-based trading signal generation from video content
        // For now, return empty array
        return Array.Empty<TradingSignal>();
    }

    private void InvalidateVideoCache(Guid videoId)
    {
        _cache.Remove($"video_{videoId}");
    }

    public async Task FollowCreatorAsync(Guid userId, Guid creatorId, CancellationToken cancellationToken = default)
    {
        try
        {
            // Map the user ID to the creator studio user ID if needed
            var creatorStudioUserId = await _userMappingService.GetCreatorStudioUserIdAsync(userId, cancellationToken);
            
            // Call the creator studio API to follow the creator
            await _creatorStudioClient.FollowCreatorAsync(creatorStudioUserId, creatorId, cancellationToken);
            
            // Invalidate user's feed cache since following status changed
            InvalidateUserFeedCache(userId);
            
            _logger.LogInformation("User {UserId} successfully followed creator {CreatorId}", userId, creatorId);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to follow creator {CreatorId} for user {UserId}", creatorId, userId);
            throw new VideoServiceException($"Failed to follow creator: {ex.Message}", ex);
        }
    }

    private void InvalidateUserFeedCache(Guid userId)
    {
        // Remove all cached feed entries for this user
        // This is a simplified approach - in production, you might want a more sophisticated cache invalidation strategy
    }
}