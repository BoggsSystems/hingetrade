using CreatorStudio.Domain.Common;

namespace CreatorStudio.Domain.Entities;

public class VideoAnalytics : BaseEntity
{
    public Guid VideoId { get; set; }
    public DateTime Date { get; set; }
    
    // Daily metrics
    public int Views { get; set; }
    public int UniqueViews { get; set; }
    public long TotalWatchTimeSeconds { get; set; }
    public decimal AverageWatchTimeSeconds { get; set; }
    public decimal WatchTimePercentage { get; set; }
    
    // Engagement metrics
    public int Likes { get; set; }
    public int Shares { get; set; }
    public int Comments { get; set; }
    public decimal EngagementRate { get; set; }
    
    // Traffic sources
    public int DirectTraffic { get; set; }
    public int SearchTraffic { get; set; }
    public int SocialTraffic { get; set; }
    public int ReferralTraffic { get; set; }
    
    // Demographics
    public string? TopCountries { get; set; } // JSON array
    public string? AgeGroupDistribution { get; set; } // JSON object
    public string? DeviceTypes { get; set; } // JSON object
    
    // Revenue (if applicable)
    public decimal Revenue { get; set; }
    public int SubscriptionConversions { get; set; }
    public decimal TipRevenue { get; set; }

    // Navigation properties
    public Video Video { get; set; } = null!;
}