namespace CreatorStudio.Domain.Enums;

public enum VideoStatus
{
    Draft,
    Uploading,
    Processing,
    ProcessingFailed,
    NeedsReview,
    ReadyToPublish,
    Published,
    Unpublished,
    Archived,
    Deleted
}

public enum VideoVisibility
{
    Private,
    Unlisted,
    Public,
    Subscribers
}

public enum VideoQuality
{
    Auto,
    Low_360p,
    Medium_720p,
    High_1080p,
    Ultra_4K
}

public enum ProcessingStatus
{
    Pending,
    InProgress,
    Completed,
    Failed,
    Cancelled
}