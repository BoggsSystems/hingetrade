using CreatorStudio.Domain.Common;

namespace CreatorStudio.Domain.Entities;

public class CreatorProfile : AuditableEntity
{
    public Guid UserId { get; set; }
    public string DisplayName { get; set; } = string.Empty;
    public string? Bio { get; set; }
    public string? ProfileImageUrl { get; set; }
    public string? BannerImageUrl { get; set; }
    public string? Website { get; set; }
    public string? TwitterHandle { get; set; }
    public string? LinkedInProfile { get; set; }
    
    // Analytics
    public int SubscriberCount { get; set; }
    public int TotalViews { get; set; }
    public int TotalVideos { get; set; }
    public decimal TotalRevenue { get; set; }
    
    // Settings
    public bool IsPublic { get; set; } = true;
    public bool AllowComments { get; set; } = true;
    public bool AllowSubscriptions { get; set; } = true;
    
    // Monetization settings
    public decimal? MonthlySubscriptionPrice { get; set; }
    public decimal? PremiumSubscriptionPrice { get; set; }
    public bool EnableTips { get; set; } = true;
    public bool EnableSponsorship { get; set; } = true;

    // Navigation properties
    public User User { get; set; } = null!;
    public ICollection<Subscription> Subscribers { get; set; } = new List<Subscription>();
}