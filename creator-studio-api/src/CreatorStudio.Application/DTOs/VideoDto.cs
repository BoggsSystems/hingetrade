using CreatorStudio.Domain.Enums;

namespace CreatorStudio.Application.DTOs;

public class VideoDto
{
    public Guid Id { get; set; }
    public Guid CreatorId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? ThumbnailUrl { get; set; }
    public VideoStatus Status { get; set; }
    public VideoVisibility Visibility { get; set; }
    
    // Video file information
    public string? VideoUrl { get; set; }
    public int? DurationSeconds { get; set; }
    public long? FileSizeBytes { get; set; }
    
    // Content metadata
    public string[]? Tags { get; set; }
    public string[]? TradingSymbols { get; set; }
    public bool HasTranscription { get; set; }
    
    // Analytics
    public long ViewCount { get; set; }
    public decimal AverageWatchTime { get; set; }
    public decimal EngagementRate { get; set; }
    
    // Publishing
    public DateTime CreatedAt { get; set; }
    public DateTime? PublishedAt { get; set; }
    public DateTime? ScheduledAt { get; set; }
    
    // Monetization
    public bool IsSubscriberOnly { get; set; }
    public SubscriptionTier MinimumSubscriptionTier { get; set; }
    public decimal? PurchasePrice { get; set; }

    // Creator information
    public string CreatorDisplayName { get; set; } = string.Empty;
    public string? CreatorProfileImageUrl { get; set; }

    // Social/Following features
    public bool IsFromFollowedCreator { get; set; }
    public SubscriptionTier? UserSubscriptionTier { get; set; }
    public double? TrendingScore { get; set; }

    // Helper properties
    public bool IsPublished => Status == VideoStatus.Published && PublishedAt.HasValue;
    public string DurationFormatted => TimeSpan.FromSeconds(DurationSeconds ?? 0).ToString(@"mm\:ss");
    public string FileSizeFormatted => FileSizeBytes.HasValue ? FormatFileSize(FileSizeBytes.Value) : "Unknown";

    private static string FormatFileSize(long bytes)
    {
        string[] sizes = { "B", "KB", "MB", "GB", "TB" };
        double len = bytes;
        int order = 0;
        while (len >= 1024 && order < sizes.Length - 1)
        {
            order++;
            len = len / 1024;
        }
        return $"{len:0.##} {sizes[order]}";
    }
}

public class CreateVideoDto
{
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public VideoVisibility Visibility { get; set; } = VideoVisibility.Public;
    public string[]? Tags { get; set; }
    public bool IsSubscriberOnly { get; set; }
    public SubscriptionTier MinimumSubscriptionTier { get; set; } = SubscriptionTier.Free;
    public decimal? PurchasePrice { get; set; }
    public DateTime? ScheduledAt { get; set; }
}

public class UpdateVideoDto
{
    public string? Title { get; set; }
    public string? Description { get; set; }
    public VideoVisibility? Visibility { get; set; }
    public string[]? Tags { get; set; }
    public bool? IsSubscriberOnly { get; set; }
    public SubscriptionTier? MinimumSubscriptionTier { get; set; }
    public decimal? PurchasePrice { get; set; }
    public DateTime? ScheduledAt { get; set; }
}

public class SaveVideoMetadataDto
{
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string CloudinaryPublicId { get; set; } = string.Empty;
    public string? ThumbnailUrl { get; set; }
    public string? VideoUrl { get; set; }
    public float? Duration { get; set; }
    public long? FileSize { get; set; }
    public string? Format { get; set; }
    public string[] Tags { get; set; } = Array.Empty<string>();
    public Guid UserId { get; set; }
}