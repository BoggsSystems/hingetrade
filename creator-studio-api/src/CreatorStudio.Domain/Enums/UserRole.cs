namespace CreatorStudio.Domain.Enums;

public enum UserRole
{
    Viewer,
    Creator,
    Moderator,
    Admin
}

public enum SubscriptionTier
{
    Free,
    Basic,
    Premium,
    VIP
}

public enum SubscriptionStatus
{
    Active,
    Cancelled,
    Expired,
    PendingPayment,
    Suspended
}