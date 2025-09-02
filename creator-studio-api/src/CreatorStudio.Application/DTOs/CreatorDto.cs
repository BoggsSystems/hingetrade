namespace CreatorStudio.Application.DTOs;

public class CreatorProfileDto
{
    public Guid Id { get; set; }
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
    public bool IsPublic { get; set; }
    public bool AllowComments { get; set; }
    public bool AllowSubscriptions { get; set; }
    
    // Monetization settings
    public decimal? MonthlySubscriptionPrice { get; set; }
    public decimal? PremiumSubscriptionPrice { get; set; }
    public bool EnableTips { get; set; }
    public bool EnableSponsorship { get; set; }

    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }

    // User information
    public string UserEmail { get; set; } = string.Empty;
    public string UserFullName { get; set; } = string.Empty;
}

public class CreateCreatorProfileDto
{
    public string DisplayName { get; set; } = string.Empty;
    public string? Bio { get; set; }
    public string? Website { get; set; }
    public string? TwitterHandle { get; set; }
    public string? LinkedInProfile { get; set; }
    
    // Settings
    public bool IsPublic { get; set; } = true;
    public bool AllowComments { get; set; } = true;
    public bool AllowSubscriptions { get; set; } = true;
    
    // Monetization settings
    public decimal? MonthlySubscriptionPrice { get; set; }
    public decimal? PremiumSubscriptionPrice { get; set; }
    public bool EnableTips { get; set; } = true;
    public bool EnableSponsorship { get; set; } = true;
}

public class UpdateCreatorProfileDto
{
    public string? DisplayName { get; set; }
    public string? Bio { get; set; }
    public string? Website { get; set; }
    public string? TwitterHandle { get; set; }
    public string? LinkedInProfile { get; set; }
    
    // Settings
    public bool? IsPublic { get; set; }
    public bool? AllowComments { get; set; }
    public bool? AllowSubscriptions { get; set; }
    
    // Monetization settings
    public decimal? MonthlySubscriptionPrice { get; set; }
    public decimal? PremiumSubscriptionPrice { get; set; }
    public bool? EnableTips { get; set; }
    public bool? EnableSponsorship { get; set; }
}