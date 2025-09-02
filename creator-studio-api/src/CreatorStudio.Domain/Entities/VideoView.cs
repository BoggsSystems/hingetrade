using CreatorStudio.Domain.Common;

namespace CreatorStudio.Domain.Entities;

public class VideoView : BaseEntity
{
    public Guid VideoId { get; set; }
    public Guid? UserId { get; set; }
    public string? AnonymousId { get; set; } // For non-logged-in users
    public string IpAddress { get; set; } = string.Empty;
    public string? UserAgent { get; set; }
    public string? Country { get; set; }
    public string? City { get; set; }
    public string? DeviceType { get; set; }
    public string? TrafficSource { get; set; }
    public string? ReferrerUrl { get; set; }
    
    // Watch data
    public int WatchTimeSeconds { get; set; }
    public int MaxWatchTimeSeconds { get; set; }
    public decimal WatchPercentage { get; set; }
    public bool CompletedView { get; set; } // Watched >= 80% or full duration
    
    // Engagement
    public bool Liked { get; set; }
    public bool Shared { get; set; }
    public DateTime? LastWatchedAt { get; set; }

    // Navigation properties
    public Video Video { get; set; } = null!;
    public User? User { get; set; }
}