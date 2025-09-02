using CreatorStudio.Domain.Enums;

namespace CreatorStudio.Application.DTOs;

public class SubscriptionDto
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public Guid CreatorId { get; set; }
    public SubscriptionTier SubscriptionTier { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    public bool IsActive { get; set; }
    public bool AutoRenew { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    
    // Creator information
    public string CreatorName { get; set; } = string.Empty;
    public string? CreatorProfileImageUrl { get; set; }
    public int CreatorVideoCount { get; set; }
}