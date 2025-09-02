using CreatorStudio.Domain.Entities;

namespace CreatorStudio.Domain.Services;

/// <summary>
/// Service for tracking video views and watch time
/// </summary>
public interface IVideoViewTrackingService
{
    /// <summary>
    /// Starts a new video viewing session
    /// </summary>
    /// <param name="videoId">The video being viewed</param>
    /// <param name="userId">The user watching (null for anonymous)</param>
    /// <param name="anonymousId">Anonymous identifier for non-authenticated users</param>
    /// <param name="ipAddress">Client IP address</param>
    /// <param name="userAgent">Client user agent</param>
    /// <returns>View session ID</returns>
    Task<Guid> StartViewSessionAsync(
        Guid videoId, 
        Guid? userId = null, 
        string? anonymousId = null,
        string? ipAddress = null,
        string? userAgent = null,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Updates watch progress for an active session
    /// </summary>
    /// <param name="sessionId">The view session ID</param>
    /// <param name="watchTimeSeconds">Current watch time in seconds</param>
    /// <param name="maxWatchTimeSeconds">Maximum time watched in session</param>
    /// <returns>Success status</returns>
    Task<bool> UpdateViewProgressAsync(
        Guid sessionId,
        double watchTimeSeconds,
        double maxWatchTimeSeconds,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Completes a viewing session
    /// </summary>
    /// <param name="sessionId">The view session ID</param>
    /// <param name="finalWatchTimeSeconds">Final watch time</param>
    /// <param name="completed">Whether the video was watched to completion</param>
    /// <returns>Success status</returns>
    Task<bool> CompleteViewSessionAsync(
        Guid sessionId,
        double finalWatchTimeSeconds,
        bool completed,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Records a like/unlike action during viewing
    /// </summary>
    Task<bool> RecordViewEngagementAsync(
        Guid sessionId,
        bool liked,
        bool? shared = null,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Gets view statistics for a video
    /// </summary>
    Task<VideoViewStats> GetVideoViewStatsAsync(
        Guid videoId,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Checks if a view session is valid and not fraudulent
    /// </summary>
    Task<bool> ValidateViewSessionAsync(
        Guid videoId,
        string? ipAddress,
        string? userAgent,
        Guid? userId = null,
        CancellationToken cancellationToken = default);
}

/// <summary>
/// Video view statistics
/// </summary>
public class VideoViewStats
{
    public int TotalViews { get; set; }
    public int UniqueViews { get; set; }
    public double AverageWatchTimeSeconds { get; set; }
    public double AverageCompletionRate { get; set; }
    public int Likes { get; set; }
    public int Shares { get; set; }
    public double EngagementRate { get; set; }
    public DateTime? LastViewedAt { get; set; }
}