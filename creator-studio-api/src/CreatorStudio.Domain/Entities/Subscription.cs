using CreatorStudio.Domain.Common;
using CreatorStudio.Domain.Enums;

namespace CreatorStudio.Domain.Entities;

public class Subscription : AuditableEntity
{
    public Guid UserId { get; set; }
    public Guid CreatorId { get; set; }
    public SubscriptionTier Tier { get; set; } = SubscriptionTier.Free;
    public SubscriptionStatus Status { get; set; } = SubscriptionStatus.Active;
    
    // Pricing
    public decimal Price { get; set; }
    public string Currency { get; set; } = "USD";
    
    // Billing
    public DateTime? NextBillingDate { get; set; }
    public DateTime? CancelledAt { get; set; }
    public DateTime? ExpiresAt { get; set; }
    public string? CancellationReason { get; set; }
    
    // Payment integration
    public string? StripeSubscriptionId { get; set; }
    public string? PaymentMethodId { get; set; }

    // Navigation properties
    public User User { get; set; } = null!;
    public CreatorProfile Creator { get; set; } = null!;
    
    // Helper properties
    public bool IsActive => Status == SubscriptionStatus.Active && 
                           (ExpiresAt == null || ExpiresAt > DateTime.UtcNow);
    public bool IsCancelled => Status == SubscriptionStatus.Cancelled;
    public bool IsExpired => ExpiresAt.HasValue && ExpiresAt < DateTime.UtcNow;
}