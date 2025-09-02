using CreatorStudio.Domain.Common;

namespace CreatorStudio.Domain.Events;

public record VideoUploadedEvent(
    Guid VideoId,
    Guid CreatorId,
    string Title,
    string CloudinaryVideoId
) : IDomainEvent
{
    public Guid Id { get; } = Guid.NewGuid();
    public DateTime OccurredAt { get; } = DateTime.UtcNow;
}

public record VideoProcessingStartedEvent(
    Guid VideoId,
    Guid CreatorId,
    string CloudinaryVideoId
) : IDomainEvent
{
    public Guid Id { get; } = Guid.NewGuid();
    public DateTime OccurredAt { get; } = DateTime.UtcNow;
}

public record VideoProcessingCompletedEvent(
    Guid VideoId,
    Guid CreatorId,
    string VideoUrl,
    int DurationSeconds,
    bool HasTranscription
) : IDomainEvent
{
    public Guid Id { get; } = Guid.NewGuid();
    public DateTime OccurredAt { get; } = DateTime.UtcNow;
}

public record VideoProcessingFailedEvent(
    Guid VideoId,
    Guid CreatorId,
    string Error
) : IDomainEvent
{
    public Guid Id { get; } = Guid.NewGuid();
    public DateTime OccurredAt { get; } = DateTime.UtcNow;
}

public record VideoPublishedEvent(
    Guid VideoId,
    Guid CreatorId,
    string Title,
    string VideoUrl
) : IDomainEvent
{
    public Guid Id { get; } = Guid.NewGuid();
    public DateTime OccurredAt { get; } = DateTime.UtcNow;
}

public record VideoViewedEvent(
    Guid VideoId,
    Guid CreatorId,
    Guid? UserId,
    int WatchTimeSeconds,
    decimal WatchPercentage
) : IDomainEvent
{
    public Guid Id { get; } = Guid.NewGuid();
    public DateTime OccurredAt { get; } = DateTime.UtcNow;
}