using CreatorStudio.Domain.Common;
using CreatorStudio.Domain.Enums;

namespace CreatorStudio.Domain.Entities;

public class Video : AuditableEntity
{
    public Guid CreatorId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? ThumbnailUrl { get; set; }
    public VideoStatus Status { get; set; } = VideoStatus.Draft;
    public VideoVisibility Visibility { get; set; } = VideoVisibility.Public;
    
    // Video file information
    public string? CloudinaryVideoId { get; set; }
    public string? CloudinaryPublicId { get; set; }
    public string? OriginalFileName { get; set; }
    public long? FileSizeBytes { get; set; }
    public int? DurationSeconds { get; set; }
    public string? VideoUrl { get; set; }
    
    // Processing information
    public ProcessingStatus ProcessingStatus { get; set; } = ProcessingStatus.Pending;
    public string? ProcessingError { get; set; }
    public DateTime? ProcessingStartedAt { get; set; }
    public DateTime? ProcessingCompletedAt { get; set; }
    
    // Content metadata
    public string[]? Tags { get; set; }
    public string[]? TradingSymbols { get; set; }
    public string? TranscriptionText { get; set; }
    public bool HasTranscription { get; set; }
    
    // Analytics
    public long ViewCount { get; set; }
    public long UniqueViewCount { get; set; }
    public decimal AverageWatchTime { get; set; }
    public decimal EngagementRate { get; set; }
    
    // Publishing
    public DateTime? PublishedAt { get; set; }
    public DateTime? UnpublishedAt { get; set; }
    public DateTime? ScheduledAt { get; set; }
    public int PublishCount { get; set; } = 0;
    public DateTime? LastStatusChange { get; set; }
    
    // Monetization
    public bool IsSubscriberOnly { get; set; }
    public SubscriptionTier MinimumSubscriptionTier { get; set; } = SubscriptionTier.Free;
    public decimal? PurchasePrice { get; set; }

    // Navigation properties
    public User User { get; set; } = null!;
    public ICollection<VideoView> Views { get; set; } = new List<VideoView>();
    public ICollection<VideoAnalytics> Analytics { get; set; } = new List<VideoAnalytics>();
    public ICollection<VideoTag> VideoTags { get; set; } = new List<VideoTag>();

    // Helper methods
    public bool IsPublished => Status == VideoStatus.Published && PublishedAt.HasValue;
    public bool IsUnpublished => Status == VideoStatus.Unpublished;
    public bool IsReadyToPublish => Status == VideoStatus.ReadyToPublish;
    public bool IsProcessing => ProcessingStatus == ProcessingStatus.InProgress;
    public bool IsProcessed => ProcessingStatus == ProcessingStatus.Completed;
    public bool CanBePublished => Status == VideoStatus.ReadyToPublish && IsProcessed;
    public bool CanBeUnpublished => Status == VideoStatus.Published;
    public string DurationFormatted => TimeSpan.FromSeconds(DurationSeconds ?? 0).ToString(@"mm\:ss");
}