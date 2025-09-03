using System.Text.Json;

namespace TraderApi.Features.Videos;

/// <summary>
/// HTTP client for communicating with Creator Studio API
/// </summary>
public interface ICreatorStudioClient
{
    Task<CreatorStudioVideoResponse> GetVideoFeedAsync(Guid userId, VideoFeedRequest request, CancellationToken cancellationToken = default);
    Task<CreatorStudioVideoResponse> GetVideosBySymbolAsync(string symbol, int page, int pageSize, CancellationToken cancellationToken = default);
    Task<CreatorStudioVideo> GetVideoAsync(Guid videoId, CancellationToken cancellationToken = default);
    Task<bool> RecordInteractionAsync(Guid userId, Guid videoId, VideoInteractionType interactionType, bool value, CancellationToken cancellationToken = default);
    Task<CreatorStudioCreator> GetCreatorAsync(Guid creatorId, CancellationToken cancellationToken = default);
    Task FollowCreatorAsync(Guid userId, Guid creatorId, CancellationToken cancellationToken = default);
}

public class CreatorStudioClient : ICreatorStudioClient
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<CreatorStudioClient> _logger;
    private readonly IServiceAuthenticationService _serviceAuth;
    private readonly JsonSerializerOptions _jsonOptions;

    public CreatorStudioClient(
        HttpClient httpClient, 
        ILogger<CreatorStudioClient> logger,
        IServiceAuthenticationService serviceAuth)
    {
        _httpClient = httpClient;
        _logger = logger;
        _serviceAuth = serviceAuth;
        _jsonOptions = new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
            PropertyNameCaseInsensitive = true
        };
    }

    /// <summary>
    /// Sets the service authentication token for requests to Creator Studio API
    /// </summary>
    private void SetServiceAuthToken()
    {
        var token = _serviceAuth.GenerateServiceToken(
            serviceName: "hingetrade-api",
            permissions: new[] { "videos:read", "creators:read", "interactions:write" },
            expiresIn: TimeSpan.FromHours(1)
        );
        
        _httpClient.DefaultRequestHeaders.Authorization = 
            new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", token);
    }

    public async Task<CreatorStudioVideoResponse> GetVideoFeedAsync(Guid userId, VideoFeedRequest request, CancellationToken cancellationToken = default)
    {
        try
        {
            // Set service authentication token
            SetServiceAuthToken();
            
            // Use public feed endpoint instead of user-specific endpoint
            string endpoint = request.FeedType switch
            {
                VideoFeedType.Trending => "videos/public/trending",
                VideoFeedType.Following => $"videos/public/following?userId={userId}",
                VideoFeedType.SymbolBased => "videos/public/by-symbol",
                _ => "videos/public/feed"
            };
            
            var query = $"?page={request.Page}&pageSize={request.PageSize}";
            
            if (!string.IsNullOrEmpty(request.Symbol))
            {
                query += $"&symbol={request.Symbol}";
            }

            var response = await _httpClient.GetAsync($"{endpoint}{query}", cancellationToken);
            response.EnsureSuccessStatusCode();

            var content = await response.Content.ReadAsStringAsync(cancellationToken);
            var result = JsonSerializer.Deserialize<CreatorStudioVideoResponse>(content, _jsonOptions);

            _logger.LogDebug("Retrieved {Count} videos from Creator Studio API", result?.Videos?.Length ?? 0);
            
            return result ?? new CreatorStudioVideoResponse(Array.Empty<CreatorStudioVideo>(), 0);
        }
        catch (HttpRequestException ex)
        {
            _logger.LogError(ex, "Failed to get video feed from Creator Studio API");
            throw new VideoServiceException("Failed to retrieve video feed", ex);
        }
        catch (JsonException ex)
        {
            _logger.LogError(ex, "Failed to deserialize video feed response");
            throw new VideoServiceException("Invalid response format from video service", ex);
        }
    }

    public async Task<CreatorStudioVideoResponse> GetVideosBySymbolAsync(string symbol, int page, int pageSize, CancellationToken cancellationToken = default)
    {
        try
        {
            var query = $"?symbol={symbol}&page={page}&pageSize={pageSize}";
            var response = await _httpClient.GetAsync($"videos/by-symbol{query}", cancellationToken);
            response.EnsureSuccessStatusCode();

            var content = await response.Content.ReadAsStringAsync(cancellationToken);
            var result = JsonSerializer.Deserialize<CreatorStudioVideoResponse>(content, _jsonOptions);

            _logger.LogDebug("Retrieved {Count} videos for symbol {Symbol}", result?.Videos?.Length ?? 0, symbol);
            
            return result ?? new CreatorStudioVideoResponse(Array.Empty<CreatorStudioVideo>(), 0);
        }
        catch (HttpRequestException ex)
        {
            _logger.LogError(ex, "Failed to get videos by symbol {Symbol}", symbol);
            throw new VideoServiceException($"Failed to retrieve videos for symbol {symbol}", ex);
        }
    }

    public async Task<CreatorStudioVideo> GetVideoAsync(Guid videoId, CancellationToken cancellationToken = default)
    {
        try
        {
            var response = await _httpClient.GetAsync($"videos/{videoId}", cancellationToken);
            response.EnsureSuccessStatusCode();

            var content = await response.Content.ReadAsStringAsync(cancellationToken);
            var result = JsonSerializer.Deserialize<CreatorStudioVideo>(content, _jsonOptions);

            return result ?? throw new VideoServiceException("Video not found");
        }
        catch (HttpRequestException ex)
        {
            _logger.LogError(ex, "Failed to get video {VideoId}", videoId);
            throw new VideoServiceException($"Failed to retrieve video {videoId}", ex);
        }
    }

    public async Task<bool> RecordInteractionAsync(Guid userId, Guid videoId, VideoInteractionType interactionType, bool value, CancellationToken cancellationToken = default)
    {
        try
        {
            var request = new
            {
                userId,
                videoId,
                interactionType = interactionType.ToString(),
                value
            };

            var json = JsonSerializer.Serialize(request, _jsonOptions);
            var content = new StringContent(json, System.Text.Encoding.UTF8, "application/json");

            var response = await _httpClient.PostAsync("videos/interactions", content, cancellationToken);
            
            if (response.IsSuccessStatusCode)
            {
                _logger.LogDebug("Recorded {InteractionType} interaction for video {VideoId} by user {UserId}", 
                    interactionType, videoId, userId);
                return true;
            }

            _logger.LogWarning("Failed to record interaction: {StatusCode}", response.StatusCode);
            return false;
        }
        catch (HttpRequestException ex)
        {
            _logger.LogError(ex, "Failed to record video interaction");
            return false;
        }
    }

    public async Task<CreatorStudioCreator> GetCreatorAsync(Guid creatorId, CancellationToken cancellationToken = default)
    {
        try
        {
            var response = await _httpClient.GetAsync($"creators/{creatorId}", cancellationToken);
            response.EnsureSuccessStatusCode();

            var content = await response.Content.ReadAsStringAsync(cancellationToken);
            var result = JsonSerializer.Deserialize<CreatorStudioCreator>(content, _jsonOptions);

            return result ?? throw new VideoServiceException("Creator not found");
        }
        catch (HttpRequestException ex)
        {
            _logger.LogError(ex, "Failed to get creator {CreatorId}", creatorId);
            throw new VideoServiceException($"Failed to retrieve creator {creatorId}", ex);
        }
    }

    public async Task FollowCreatorAsync(Guid userId, Guid creatorId, CancellationToken cancellationToken = default)
    {
        try
        {
            var requestUri = $"/api/subscriptions/{userId}/follow/{creatorId}";
            
            var requestMessage = new HttpRequestMessage(HttpMethod.Post, requestUri);
            await _serviceAuth.AuthenticateServiceRequestAsync(requestMessage, cancellationToken);
            
            var response = await _httpClient.SendAsync(requestMessage, cancellationToken);
            
            if (response.IsSuccessStatusCode)
            {
                _logger.LogInformation("Successfully followed creator {CreatorId} for user {UserId}", creatorId, userId);
                return;
            }
            
            var errorContent = await response.Content.ReadAsStringAsync(cancellationToken);
            var errorMessage = $"Failed to follow creator {creatorId}. Status: {response.StatusCode}, Content: {errorContent}";
            _logger.LogError(errorMessage);
            throw new VideoServiceException(errorMessage);
        }
        catch (HttpRequestException ex)
        {
            _logger.LogError(ex, "HTTP error when following creator {CreatorId} for user {UserId}", creatorId, userId);
            throw new VideoServiceException($"Failed to follow creator {creatorId}", ex);
        }
    }
}

/// <summary>
/// Raw video data from Creator Studio API
/// </summary>
public record CreatorStudioVideo(
    Guid Id,
    Guid CreatorId,
    string Title,
    string? Description,
    string? ThumbnailUrl,
    string? VideoUrl,
    int Status,
    int Visibility,
    int? DurationSeconds,
    long? FileSizeBytes,
    string[]? Tags,
    DateTime CreatedAt,
    DateTime? PublishedAt,
    bool IsSubscriberOnly,
    long ViewCount,
    decimal AverageWatchTime,
    decimal EngagementRate,
    string CreatorDisplayName,
    string? CreatorProfileImageUrl
);

/// <summary>
/// Video response from Creator Studio API
/// </summary>
public record CreatorStudioVideoResponse(
    CreatorStudioVideo[] Videos,
    int Total
);

/// <summary>
/// Creator data from Creator Studio API
/// </summary>
public record CreatorStudioCreator(
    Guid Id,
    string DisplayName,
    string? Bio,
    string? ProfileImageUrl,
    int FollowerCount,
    int VideoCount
);

/// <summary>
/// Custom exception for video service errors
/// </summary>
public class VideoServiceException : Exception
{
    public VideoServiceException(string message) : base(message) { }
    public VideoServiceException(string message, Exception innerException) : base(message, innerException) { }
}