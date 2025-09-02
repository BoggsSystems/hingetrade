using CreatorStudio.Domain.Entities;
using CreatorStudio.Domain.Enums;
using CreatorStudio.Domain.Services;
using Microsoft.Extensions.Logging;

namespace CreatorStudio.Application.Services;

/// <summary>
/// Implementation of video status management service
/// </summary>
public class VideoStatusService : IVideoStatusService
{
    private readonly ILogger<VideoStatusService> _logger;

    // Define valid status transitions
    private static readonly Dictionary<VideoStatus, HashSet<VideoStatus>> ValidTransitions = new()
    {
        [VideoStatus.Draft] = new() { VideoStatus.Uploading, VideoStatus.Deleted },
        [VideoStatus.Uploading] = new() { VideoStatus.Processing, VideoStatus.ProcessingFailed, VideoStatus.Deleted },
        [VideoStatus.Processing] = new() { VideoStatus.ReadyToPublish, VideoStatus.ProcessingFailed, VideoStatus.Deleted },
        [VideoStatus.ProcessingFailed] = new() { VideoStatus.Uploading, VideoStatus.Deleted }, // Allow retry
        [VideoStatus.NeedsReview] = new() { VideoStatus.ReadyToPublish, VideoStatus.Draft, VideoStatus.Deleted },
        [VideoStatus.ReadyToPublish] = new() { VideoStatus.Published, VideoStatus.Draft, VideoStatus.Deleted },
        [VideoStatus.Published] = new() { VideoStatus.Unpublished, VideoStatus.Archived, VideoStatus.Deleted },
        [VideoStatus.Unpublished] = new() { VideoStatus.Published, VideoStatus.Archived, VideoStatus.Deleted },
        [VideoStatus.Archived] = new() { VideoStatus.Published, VideoStatus.Deleted },
        [VideoStatus.Deleted] = new() { } // Terminal state
    };

    public VideoStatusService(ILogger<VideoStatusService> logger)
    {
        _logger = logger;
    }

    public bool IsValidTransition(VideoStatus fromStatus, VideoStatus toStatus)
    {
        return ValidTransitions.ContainsKey(fromStatus) && 
               ValidTransitions[fromStatus].Contains(toStatus);
    }

    public async Task<bool> TransitionStatusAsync(Video video, VideoStatus newStatus, string? reason = null)
    {
        if (!IsValidTransition(video.Status, newStatus))
        {
            _logger.LogWarning("Invalid status transition for video {VideoId}: {FromStatus} -> {ToStatus}", 
                video.Id, video.Status, newStatus);
            return false;
        }

        var oldStatus = video.Status;
        video.Status = newStatus;
        video.LastStatusChange = DateTime.UtcNow;

        _logger.LogInformation("Video {VideoId} status changed: {FromStatus} -> {ToStatus}. Reason: {Reason}",
            video.Id, oldStatus, newStatus, reason ?? "Not specified");

        return true;
    }

    public async Task<bool> PublishVideoAsync(Video video)
    {
        var validation = ValidateCanPublish(video);
        if (!validation.IsValid)
        {
            _logger.LogWarning("Cannot publish video {VideoId}: {Error}", video.Id, validation.ErrorMessage);
            return false;
        }

        var success = await TransitionStatusAsync(video, VideoStatus.Published, "Published by user");
        if (success)
        {
            video.PublishedAt = DateTime.UtcNow;
            video.PublishCount++;
            
            _logger.LogInformation("Video {VideoId} published successfully. Publish count: {PublishCount}", 
                video.Id, video.PublishCount);
        }

        return success;
    }

    public async Task<bool> UnpublishVideoAsync(Video video, string? reason = null)
    {
        var validation = ValidateCanUnpublish(video);
        if (!validation.IsValid)
        {
            _logger.LogWarning("Cannot unpublish video {VideoId}: {Error}", video.Id, validation.ErrorMessage);
            return false;
        }

        var success = await TransitionStatusAsync(video, VideoStatus.Unpublished, reason ?? "Unpublished by user");
        if (success)
        {
            video.UnpublishedAt = DateTime.UtcNow;
            
            _logger.LogInformation("Video {VideoId} unpublished successfully. Reason: {Reason}", 
                video.Id, reason ?? "Not specified");
        }

        return success;
    }

    public async Task<bool> RepublishVideoAsync(Video video)
    {
        if (video.Status != VideoStatus.Unpublished)
        {
            _logger.LogWarning("Cannot republish video {VideoId}: Current status is {Status}, expected Unpublished", 
                video.Id, video.Status);
            return false;
        }

        var success = await TransitionStatusAsync(video, VideoStatus.Published, "Republished by user");
        if (success)
        {
            video.PublishedAt = DateTime.UtcNow;
            video.PublishCount++;
            
            _logger.LogInformation("Video {VideoId} republished successfully. Total publish count: {PublishCount}", 
                video.Id, video.PublishCount);
        }

        return success;
    }

    public IEnumerable<VideoStatus> GetAllowedTransitions(VideoStatus currentStatus)
    {
        return ValidTransitions.ContainsKey(currentStatus) 
            ? ValidTransitions[currentStatus] 
            : Enumerable.Empty<VideoStatus>();
    }

    public ValidationResult ValidateCanPublish(Video video)
    {
        var errors = new List<string>();

        // Must be in ReadyToPublish status
        if (video.Status != VideoStatus.ReadyToPublish)
        {
            errors.Add($"Video must be in ReadyToPublish status. Current status: {video.Status}");
        }

        // Must have completed processing
        if (video.ProcessingStatus != ProcessingStatus.Completed)
        {
            errors.Add($"Video processing must be completed. Current processing status: {video.ProcessingStatus}");
        }

        // Must have a video URL
        if (string.IsNullOrEmpty(video.VideoUrl))
        {
            errors.Add("Video must have a valid video URL");
        }

        // Must have a title
        if (string.IsNullOrEmpty(video.Title))
        {
            errors.Add("Video must have a title");
        }

        // Check duration is reasonable (optional warning)
        if (video.DurationSeconds.HasValue && video.DurationSeconds < 1)
        {
            errors.Add("Video duration appears to be invalid");
        }

        return errors.Count == 0 
            ? ValidationResult.Success() 
            : ValidationResult.Failure(errors);
    }

    public ValidationResult ValidateCanUnpublish(Video video)
    {
        var errors = new List<string>();

        // Must be currently published
        if (video.Status != VideoStatus.Published)
        {
            errors.Add($"Video must be published to unpublish. Current status: {video.Status}");
        }

        // Must have been published at some point
        if (!video.PublishedAt.HasValue)
        {
            errors.Add("Video has no published date");
        }

        return errors.Count == 0 
            ? ValidationResult.Success() 
            : ValidationResult.Failure(errors);
    }
}