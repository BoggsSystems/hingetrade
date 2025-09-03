using FluentValidation;

namespace TraderApi.Features.Videos;

/// <summary>
/// Video data enriched with trading metadata for HingeTrade
/// </summary>
public record VideoDto(
    Guid Id,
    Guid CreatorId,
    string Title,
    string? Description,
    string? ThumbnailUrl,
    string? VideoUrl,
    VideoStatus Status,
    VideoVisibility Visibility,
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
    string? CreatorProfileImageUrl,
    
    // Trading-specific enhancements
    string[] MentionedSymbols,
    Dictionary<string, decimal> RealTimePrices,
    TradingSignal[] TradingSignals
);

/// <summary>
/// Video feed request parameters
/// </summary>
public record VideoFeedRequest(
    int Page = 1,
    int PageSize = 20,
    VideoFeedType FeedType = VideoFeedType.Personalized,
    string? Symbol = null,
    bool? FollowingOnly = null
);

/// <summary>
/// Video interaction request
/// </summary>
public record VideoInteractionRequest(
    VideoInteractionType InteractionType,
    bool Value
);

/// <summary>
/// Video feed response
/// </summary>
public record VideoFeedResponse(
    VideoDto[] Videos,
    int Total,
    int Page,
    int PageSize,
    bool HasMore
);

/// <summary>
/// Creator profile information
/// </summary>
public record CreatorDto(
    Guid Id,
    string DisplayName,
    string? Bio,
    string? ProfileImageUrl,
    int FollowerCount,
    int VideoCount,
    bool IsFollowing,
    CreatorVerificationStatus VerificationStatus
);

/// <summary>
/// Trading signal extracted from video content
/// </summary>
public record TradingSignal(
    string Symbol,
    SignalType Type,
    decimal? TargetPrice,
    decimal? StopLoss,
    string? Reasoning,
    decimal Confidence,
    DateTime Timestamp
);

/// <summary>
/// Video feed type enumeration
/// </summary>
public enum VideoFeedType
{
    Personalized,
    Trending,
    Following,
    SymbolBased,
    Educational,
    TechnicalAnalysis,
    FundamentalAnalysis
}

/// <summary>
/// Video interaction type
/// </summary>
public enum VideoInteractionType
{
    Like,
    Save,
    Share,
    Follow
}

/// <summary>
/// Video status from Creator Studio
/// </summary>
public enum VideoStatus
{
    Draft,
    Processing,
    Published,
    Archived
}

/// <summary>
/// Video visibility settings
/// </summary>
public enum VideoVisibility
{
    Public,
    Unlisted,
    Private,
    SubscribersOnly
}

/// <summary>
/// Creator verification status
/// </summary>
public enum CreatorVerificationStatus
{
    Unverified,
    Pending,
    Verified,
    Professional,
    Institutional
}

/// <summary>
/// Trading signal types
/// </summary>
public enum SignalType
{
    Buy,
    Sell,
    Hold,
    StopLoss,
    TakeProfit,
    Watch,
    Avoid
}

/// <summary>
/// Validator for video feed requests
/// </summary>
public class VideoFeedRequestValidator : AbstractValidator<VideoFeedRequest>
{
    public VideoFeedRequestValidator()
    {
        RuleFor(x => x.Page)
            .GreaterThan(0);
            
        RuleFor(x => x.PageSize)
            .InclusiveBetween(1, 50);
            
        RuleFor(x => x.Symbol)
            .Matches("^[A-Z]{1,5}$")
            .When(x => !string.IsNullOrEmpty(x.Symbol));
    }
}

/// <summary>
/// Validator for video interaction requests
/// </summary>
public class VideoInteractionRequestValidator : AbstractValidator<VideoInteractionRequest>
{
    public VideoInteractionRequestValidator()
    {
        RuleFor(x => x.InteractionType)
            .IsInEnum();
    }
}