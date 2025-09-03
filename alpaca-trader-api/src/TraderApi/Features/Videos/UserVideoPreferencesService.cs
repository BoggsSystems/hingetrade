using Microsoft.EntityFrameworkCore;
using TraderApi.Data;
using VideoView = TraderApi.Data.VideoView;
using VideoInteraction = TraderApi.Data.VideoInteraction;
using CreatorFollow = TraderApi.Data.CreatorFollow;
using UserSymbolInterest = TraderApi.Data.UserSymbolInterest;

namespace TraderApi.Features.Videos;

/// <summary>
/// Service for tracking user video preferences, watch history, and engagement
/// </summary>
public interface IUserVideoPreferencesService
{
    Task RecordVideoViewAsync(Guid userId, Guid videoId, TimeSpan watchDuration, CancellationToken cancellationToken = default);
    Task RecordVideoInteractionAsync(Guid userId, Guid videoId, VideoInteractionType interactionType, bool value, CancellationToken cancellationToken = default);
    Task<UserVideoPreferences> GetUserPreferencesAsync(Guid userId, CancellationToken cancellationToken = default);
    Task FollowCreatorAsync(Guid userId, Guid creatorId, CancellationToken cancellationToken = default);
    Task UnfollowCreatorAsync(Guid userId, Guid creatorId, CancellationToken cancellationToken = default);
    Task<Guid[]> GetFollowedCreatorsAsync(Guid userId, CancellationToken cancellationToken = default);
    Task AddSymbolInterestAsync(Guid userId, string symbol, CancellationToken cancellationToken = default);
    Task<string[]> GetUserSymbolInterestsAsync(Guid userId, CancellationToken cancellationToken = default);
}

public class UserVideoPreferencesService : IUserVideoPreferencesService
{
    private readonly AppDbContext _dbContext;
    private readonly ILogger<UserVideoPreferencesService> _logger;

    public UserVideoPreferencesService(
        AppDbContext dbContext,
        ILogger<UserVideoPreferencesService> logger)
    {
        _dbContext = dbContext;
        _logger = logger;
    }

    public async Task RecordVideoViewAsync(Guid userId, Guid videoId, TimeSpan watchDuration, CancellationToken cancellationToken = default)
    {
        try
        {
            var existingView = await _dbContext.VideoViews
                .FirstOrDefaultAsync(v => v.UserId == userId && v.VideoId == videoId, cancellationToken);

            if (existingView != null)
            {
                // Update existing view with longer watch duration
                if (watchDuration > existingView.WatchDuration)
                {
                    existingView.WatchDuration = watchDuration;
                    existingView.LastViewedAt = DateTime.UtcNow;
                    existingView.ViewCount++;
                }
            }
            else
            {
                // Create new view record
                var videoView = new VideoView
                {
                    Id = Guid.NewGuid(),
                    UserId = userId,
                    VideoId = videoId,
                    WatchDuration = watchDuration,
                    ViewCount = 1,
                    FirstViewedAt = DateTime.UtcNow,
                    LastViewedAt = DateTime.UtcNow
                };
                
                _dbContext.VideoViews.Add(videoView);
            }

            await _dbContext.SaveChangesAsync(cancellationToken);
            
            _logger.LogDebug("Recorded video view for user {UserId}, video {VideoId}, duration {Duration}", 
                userId, videoId, watchDuration);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to record video view for user {UserId}, video {VideoId}", userId, videoId);
            throw;
        }
    }

    public async Task RecordVideoInteractionAsync(Guid userId, Guid videoId, VideoInteractionType interactionType, bool value, CancellationToken cancellationToken = default)
    {
        try
        {
            var existingInteraction = await _dbContext.VideoInteractions
                .FirstOrDefaultAsync(i => i.UserId == userId && i.VideoId == videoId && i.InteractionType == interactionType, cancellationToken);

            if (existingInteraction != null)
            {
                existingInteraction.Value = value;
                existingInteraction.UpdatedAt = DateTime.UtcNow;
            }
            else
            {
                var interaction = new VideoInteraction
                {
                    Id = Guid.NewGuid(),
                    UserId = userId,
                    VideoId = videoId,
                    InteractionType = interactionType,
                    Value = value,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };
                
                _dbContext.VideoInteractions.Add(interaction);
            }

            await _dbContext.SaveChangesAsync(cancellationToken);
            
            _logger.LogDebug("Recorded video interaction for user {UserId}, video {VideoId}, type {InteractionType}, value {Value}", 
                userId, videoId, interactionType, value);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to record video interaction for user {UserId}, video {VideoId}", userId, videoId);
            throw;
        }
    }

    public async Task<UserVideoPreferences> GetUserPreferencesAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        try
        {
            // Get user's viewing history
            var viewHistory = await _dbContext.VideoViews
                .Where(v => v.UserId == userId)
                .OrderByDescending(v => v.LastViewedAt)
                .Take(100)
                .Select(v => new VideoViewSummary(v.VideoId, v.WatchDuration, v.ViewCount, v.LastViewedAt))
                .ToArrayAsync(cancellationToken);

            // Get user's interactions
            var interactions = await _dbContext.VideoInteractions
                .Where(i => i.UserId == userId)
                .ToArrayAsync(cancellationToken);

            // Get followed creators
            var followedCreators = await _dbContext.CreatorFollows
                .Where(f => f.UserId == userId && f.IsFollowing)
                .Select(f => f.CreatorId)
                .ToArrayAsync(cancellationToken);

            // Get symbol interests
            var symbolInterests = await _dbContext.UserSymbolInterests
                .Where(s => s.UserId == userId)
                .OrderByDescending(s => s.InterestScore)
                .Select(s => s.Symbol)
                .ToArrayAsync(cancellationToken);

            return new UserVideoPreferences(
                userId,
                viewHistory,
                interactions,
                followedCreators,
                symbolInterests
            );
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to get user preferences for user {UserId}", userId);
            throw;
        }
    }

    public async Task FollowCreatorAsync(Guid userId, Guid creatorId, CancellationToken cancellationToken = default)
    {
        try
        {
            var existingFollow = await _dbContext.CreatorFollows
                .FirstOrDefaultAsync(f => f.UserId == userId && f.CreatorId == creatorId, cancellationToken);

            if (existingFollow != null)
            {
                existingFollow.IsFollowing = true;
                existingFollow.UpdatedAt = DateTime.UtcNow;
            }
            else
            {
                var follow = new CreatorFollow
                {
                    Id = Guid.NewGuid(),
                    UserId = userId,
                    CreatorId = creatorId,
                    IsFollowing = true,
                    FollowedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };
                
                _dbContext.CreatorFollows.Add(follow);
            }

            await _dbContext.SaveChangesAsync(cancellationToken);
            
            _logger.LogInformation("User {UserId} followed creator {CreatorId}", userId, creatorId);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to follow creator {CreatorId} for user {UserId}", creatorId, userId);
            throw;
        }
    }

    public async Task UnfollowCreatorAsync(Guid userId, Guid creatorId, CancellationToken cancellationToken = default)
    {
        try
        {
            var existingFollow = await _dbContext.CreatorFollows
                .FirstOrDefaultAsync(f => f.UserId == userId && f.CreatorId == creatorId, cancellationToken);

            if (existingFollow != null)
            {
                existingFollow.IsFollowing = false;
                existingFollow.UpdatedAt = DateTime.UtcNow;
                await _dbContext.SaveChangesAsync(cancellationToken);
                
                _logger.LogInformation("User {UserId} unfollowed creator {CreatorId}", userId, creatorId);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to unfollow creator {CreatorId} for user {UserId}", creatorId, userId);
            throw;
        }
    }

    public async Task<Guid[]> GetFollowedCreatorsAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        try
        {
            return await _dbContext.CreatorFollows
                .Where(f => f.UserId == userId && f.IsFollowing)
                .Select(f => f.CreatorId)
                .ToArrayAsync(cancellationToken);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to get followed creators for user {UserId}", userId);
            throw;
        }
    }

    public async Task AddSymbolInterestAsync(Guid userId, string symbol, CancellationToken cancellationToken = default)
    {
        try
        {
            var existingInterest = await _dbContext.UserSymbolInterests
                .FirstOrDefaultAsync(s => s.UserId == userId && s.Symbol == symbol, cancellationToken);

            if (existingInterest != null)
            {
                existingInterest.InterestScore++;
                existingInterest.UpdatedAt = DateTime.UtcNow;
            }
            else
            {
                var symbolInterest = new UserSymbolInterest
                {
                    Id = Guid.NewGuid(),
                    UserId = userId,
                    Symbol = symbol,
                    InterestScore = 1,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };
                
                _dbContext.UserSymbolInterests.Add(symbolInterest);
            }

            await _dbContext.SaveChangesAsync(cancellationToken);
            
            _logger.LogDebug("Added symbol interest {Symbol} for user {UserId}", symbol, userId);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to add symbol interest {Symbol} for user {UserId}", symbol, userId);
            throw;
        }
    }

    public async Task<string[]> GetUserSymbolInterestsAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        try
        {
            return await _dbContext.UserSymbolInterests
                .Where(s => s.UserId == userId)
                .OrderByDescending(s => s.InterestScore)
                .Select(s => s.Symbol)
                .ToArrayAsync(cancellationToken);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to get symbol interests for user {UserId}", userId);
            throw;
        }
    }
}

/// <summary>
/// User video preferences and behavior data
/// </summary>
public record UserVideoPreferences(
    Guid UserId,
    VideoViewSummary[] ViewHistory,
    VideoInteraction[] Interactions,
    Guid[] FollowedCreators,
    string[] SymbolInterests
);

/// <summary>
/// Summary of a user's video viewing behavior
/// </summary>
public record VideoViewSummary(
    Guid VideoId,
    TimeSpan WatchDuration,
    int ViewCount,
    DateTime LastViewedAt
);

