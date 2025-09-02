using CreatorStudio.Domain.Common;
using CreatorStudio.Domain.Enums;

namespace CreatorStudio.Domain.Events;

public record UserRegisteredEvent(
    Guid UserId,
    string Email,
    string FullName,
    UserRole Role
) : IDomainEvent
{
    public Guid Id { get; } = Guid.NewGuid();
    public DateTime OccurredAt { get; } = DateTime.UtcNow;
}

public record UserEmailVerifiedEvent(
    Guid UserId,
    string Email
) : IDomainEvent
{
    public Guid Id { get; } = Guid.NewGuid();
    public DateTime OccurredAt { get; } = DateTime.UtcNow;
}

public record CreatorProfileCreatedEvent(
    Guid UserId,
    Guid CreatorId,
    string DisplayName
) : IDomainEvent
{
    public Guid Id { get; } = Guid.NewGuid();
    public DateTime OccurredAt { get; } = DateTime.UtcNow;
}

public record UserSubscribedEvent(
    Guid UserId,
    Guid CreatorId,
    SubscriptionTier Tier
) : IDomainEvent
{
    public Guid Id { get; } = Guid.NewGuid();
    public DateTime OccurredAt { get; } = DateTime.UtcNow;
}

public record UserUnsubscribedEvent(
    Guid UserId,
    Guid CreatorId,
    string Reason
) : IDomainEvent
{
    public Guid Id { get; } = Guid.NewGuid();
    public DateTime OccurredAt { get; } = DateTime.UtcNow;
}