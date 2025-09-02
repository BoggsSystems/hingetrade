using CreatorStudio.Domain.Entities;
using CreatorStudio.Domain.Enums;
using CreatorStudio.Domain.Interfaces;
using MediatR;
using Microsoft.Extensions.Logging;

namespace CreatorStudio.Application.Features.Videos.Commands;

public class ProcessCloudinaryWebhookCommandHandler : IRequestHandler<ProcessCloudinaryWebhookCommand, bool>
{
    private readonly IRepository<Video> _videoRepository;
    private readonly ILogger<ProcessCloudinaryWebhookCommandHandler> _logger;

    public ProcessCloudinaryWebhookCommandHandler(
        IRepository<Video> videoRepository, 
        ILogger<ProcessCloudinaryWebhookCommandHandler> logger)
    {
        _videoRepository = videoRepository;
        _logger = logger;
    }

    public async Task<bool> Handle(ProcessCloudinaryWebhookCommand request, CancellationToken cancellationToken)
    {
        try
        {
            // Find video by Cloudinary public ID
            var video = await _videoRepository.FindFirstAsync(
                v => v.CloudinaryPublicId == request.PublicId, 
                cancellationToken);

            if (video == null)
            {
                _logger.LogWarning("Video not found for Cloudinary public ID: {PublicId}", request.PublicId);
                return false;
            }

            _logger.LogInformation("Processing webhook for video {VideoId}, type: {NotificationType}, status: {Status}",
                video.Id, request.NotificationType, request.Status);

            // Update video based on webhook type and status
            bool videoUpdated = false;

            switch (request.NotificationType?.ToLower())
            {
                case "upload":
                    videoUpdated = await HandleUploadWebhook(video, request);
                    break;
                case "video_processing":
                    videoUpdated = await HandleVideoProcessingWebhook(video, request);
                    break;
                default:
                    _logger.LogWarning("Unhandled webhook notification type: {NotificationType}", request.NotificationType);
                    break;
            }

            if (videoUpdated)
            {
                video.LastStatusChange = DateTime.UtcNow;
                await _videoRepository.UpdateAsync(video, cancellationToken);
                _logger.LogInformation("Video {VideoId} updated successfully from webhook", video.Id);
            }

            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing Cloudinary webhook for public ID: {PublicId}", request.PublicId);
            return false;
        }
    }

    private async Task<bool> HandleUploadWebhook(Video video, ProcessCloudinaryWebhookCommand request)
    {
        bool updated = false;

        // Update video URL and metadata from upload
        if (!string.IsNullOrEmpty(request.VideoUrl) && video.VideoUrl != request.VideoUrl)
        {
            video.VideoUrl = request.VideoUrl;
            updated = true;
        }

        if (request.Duration.HasValue && video.DurationSeconds != (int)request.Duration.Value)
        {
            video.DurationSeconds = (int)request.Duration.Value;
            updated = true;
        }

        // Update processing status based on upload status
        switch (request.Status?.ToLower())
        {
            case "success":
            case "complete":
                if (video.ProcessingStatus != ProcessingStatus.Completed)
                {
                    video.ProcessingStatus = ProcessingStatus.Completed;
                    video.ProcessingCompletedAt = DateTime.UtcNow;
                    updated = true;
                }

                // Transition from Processing to ReadyToPublish
                if (video.Status == VideoStatus.Processing)
                {
                    video.Status = VideoStatus.ReadyToPublish;
                    updated = true;
                    _logger.LogInformation("Video {VideoId} transitioned from Processing to ReadyToPublish", video.Id);
                }
                break;

            case "error":
            case "failed":
                if (video.ProcessingStatus != ProcessingStatus.Failed)
                {
                    video.ProcessingStatus = ProcessingStatus.Failed;
                    video.Status = VideoStatus.ProcessingFailed;
                    updated = true;
                    _logger.LogWarning("Video {VideoId} processing failed", video.Id);
                }
                break;
        }

        return updated;
    }

    private async Task<bool> HandleVideoProcessingWebhook(Video video, ProcessCloudinaryWebhookCommand request)
    {
        bool updated = false;

        switch (request.Status?.ToLower())
        {
            case "in_progress":
            case "processing":
                if (video.ProcessingStatus != ProcessingStatus.InProgress)
                {
                    video.ProcessingStatus = ProcessingStatus.InProgress;
                    if (video.Status == VideoStatus.Uploading)
                    {
                        video.Status = VideoStatus.Processing;
                    }
                    updated = true;
                }
                break;

            case "complete":
            case "success":
                if (video.ProcessingStatus != ProcessingStatus.Completed)
                {
                    video.ProcessingStatus = ProcessingStatus.Completed;
                    video.ProcessingCompletedAt = DateTime.UtcNow;
                    updated = true;
                }

                // Transition to ReadyToPublish
                if (video.Status == VideoStatus.Processing)
                {
                    video.Status = VideoStatus.ReadyToPublish;
                    updated = true;
                    _logger.LogInformation("Video {VideoId} is now ready to publish", video.Id);
                }

                // Update video metadata if provided
                if (!string.IsNullOrEmpty(request.VideoUrl))
                {
                    video.VideoUrl = request.VideoUrl;
                    updated = true;
                }

                if (request.Duration.HasValue)
                {
                    video.DurationSeconds = (int)request.Duration.Value;
                    updated = true;
                }
                break;

            case "error":
            case "failed":
                if (video.ProcessingStatus != ProcessingStatus.Failed)
                {
                    video.ProcessingStatus = ProcessingStatus.Failed;
                    video.Status = VideoStatus.ProcessingFailed;
                    updated = true;
                    _logger.LogError("Video {VideoId} processing failed via webhook", video.Id);
                }
                break;
        }

        return updated;
    }
}