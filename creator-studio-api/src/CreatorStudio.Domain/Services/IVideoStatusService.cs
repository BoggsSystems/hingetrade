using CreatorStudio.Domain.Entities;
using CreatorStudio.Domain.Enums;

namespace CreatorStudio.Domain.Services;

/// <summary>
/// Service for managing video status transitions and business rules
/// </summary>
public interface IVideoStatusService
{
    /// <summary>
    /// Checks if a status transition is valid
    /// </summary>
    bool IsValidTransition(VideoStatus fromStatus, VideoStatus toStatus);

    /// <summary>
    /// Transitions a video to a new status with validation
    /// </summary>
    Task<bool> TransitionStatusAsync(Video video, VideoStatus newStatus, string? reason = null);

    /// <summary>
    /// Publishes a video (ReadyToPublish -> Published)
    /// </summary>
    Task<bool> PublishVideoAsync(Video video);

    /// <summary>
    /// Unpublishes a video (Published -> Unpublished)
    /// </summary>
    Task<bool> UnpublishVideoAsync(Video video, string? reason = null);

    /// <summary>
    /// Re-publishes an unpublished video (Unpublished -> Published)
    /// </summary>
    Task<bool> RepublishVideoAsync(Video video);

    /// <summary>
    /// Gets the next allowed statuses for a given current status
    /// </summary>
    IEnumerable<VideoStatus> GetAllowedTransitions(VideoStatus currentStatus);

    /// <summary>
    /// Validates that a video can be published
    /// </summary>
    ValidationResult ValidateCanPublish(Video video);

    /// <summary>
    /// Validates that a video can be unpublished
    /// </summary>
    ValidationResult ValidateCanUnpublish(Video video);
}

/// <summary>
/// Result of a validation operation
/// </summary>
public class ValidationResult
{
    public bool IsValid { get; set; }
    public string? ErrorMessage { get; set; }
    public List<string> Errors { get; set; } = new();

    public static ValidationResult Success() => new() { IsValid = true };
    
    public static ValidationResult Failure(string error) => new() 
    { 
        IsValid = false, 
        ErrorMessage = error,
        Errors = [error]
    };
    
    public static ValidationResult Failure(IEnumerable<string> errors) => new() 
    { 
        IsValid = false,
        ErrorMessage = string.Join("; ", errors),
        Errors = errors.ToList()
    };
}