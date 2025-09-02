using CreatorStudio.Application.DTOs;
using CreatorStudio.Domain.Entities;
using CreatorStudio.Domain.Enums;
using CreatorStudio.Domain.Interfaces;
using MediatR;

namespace CreatorStudio.Application.Features.Videos.Commands;

public record UploadVideoCommand(
    Guid CreatorId,
    Stream VideoStream,
    string FileName,
    CreateVideoDto VideoData
) : IRequest<VideoDto>;

public class UploadVideoCommandHandler : IRequestHandler<UploadVideoCommand, VideoDto>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IVideoProcessingService _videoProcessingService;

    public UploadVideoCommandHandler(
        IUnitOfWork unitOfWork,
        IVideoProcessingService videoProcessingService)
    {
        _unitOfWork = unitOfWork;
        _videoProcessingService = videoProcessingService;
    }

    public async Task<VideoDto> Handle(UploadVideoCommand request, CancellationToken cancellationToken)
    {
        // Verify creator exists
        var creator = await _unitOfWork.Repository<CreatorProfile>()
            .GetByIdAsync(request.CreatorId, cancellationToken);
        
        if (creator == null)
        {
            throw new ArgumentException($"Creator with ID {request.CreatorId} not found");
        }

        // Create video entity
        var video = new Video
        {
            CreatorId = request.CreatorId,
            Title = request.VideoData.Title,
            Description = request.VideoData.Description,
            Visibility = request.VideoData.Visibility,
            Status = VideoStatus.Uploading,
            ProcessingStatus = ProcessingStatus.Pending,
            Tags = request.VideoData.Tags,
            IsSubscriberOnly = request.VideoData.IsSubscriberOnly,
            MinimumSubscriptionTier = request.VideoData.MinimumSubscriptionTier,
            PurchasePrice = request.VideoData.PurchasePrice,
            ScheduledAt = request.VideoData.ScheduledAt,
            OriginalFileName = request.FileName
        };

        // Save video to database first
        await _unitOfWork.Repository<Video>().AddAsync(video, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        try
        {
            // Upload to Cloudinary
            var uploadRequest = new VideoUploadRequest
            {
                VideoStream = request.VideoStream,
                FileName = request.FileName,
                Title = request.VideoData.Title,
                Description = request.VideoData.Description,
                Tags = request.VideoData.Tags,
                AutoTranscribe = true,
                AutoAnalyze = true
            };

            var uploadResult = await _videoProcessingService.UploadVideoAsync(uploadRequest, cancellationToken);

            // Update video with upload results
            video.CloudinaryVideoId = uploadResult.CloudinaryVideoId;
            video.CloudinaryPublicId = uploadResult.CloudinaryPublicId;
            video.VideoUrl = uploadResult.VideoUrl;
            video.ThumbnailUrl = uploadResult.ThumbnailUrl;
            video.DurationSeconds = uploadResult.DurationSeconds;
            video.FileSizeBytes = uploadResult.FileSizeBytes;
            video.ProcessingStatus = uploadResult.ProcessingStatus;
            
            if (uploadResult.ProcessingStatus == ProcessingStatus.Failed)
            {
                video.Status = VideoStatus.ProcessingFailed;
                video.ProcessingError = uploadResult.ProcessingError;
            }
            else
            {
                video.Status = VideoStatus.Processing;
                video.ProcessingStartedAt = DateTime.UtcNow;
            }

            await _unitOfWork.Repository<Video>().UpdateAsync(video, cancellationToken);
            await _unitOfWork.SaveChangesAsync(cancellationToken);

            // Return DTO
            return new VideoDto
            {
                Id = video.Id,
                CreatorId = video.CreatorId,
                Title = video.Title,
                Description = video.Description,
                ThumbnailUrl = video.ThumbnailUrl,
                Status = video.Status,
                Visibility = video.Visibility,
                VideoUrl = video.VideoUrl,
                DurationSeconds = video.DurationSeconds,
                FileSizeBytes = video.FileSizeBytes,
                Tags = video.Tags,
                TradingSymbols = video.TradingSymbols,
                HasTranscription = video.HasTranscription,
                ViewCount = video.ViewCount,
                AverageWatchTime = video.AverageWatchTime,
                EngagementRate = video.EngagementRate,
                CreatedAt = video.CreatedAt,
                PublishedAt = video.PublishedAt,
                ScheduledAt = video.ScheduledAt,
                IsSubscriberOnly = video.IsSubscriberOnly,
                MinimumSubscriptionTier = video.MinimumSubscriptionTier,
                PurchasePrice = video.PurchasePrice,
                CreatorDisplayName = creator.DisplayName,
                CreatorProfileImageUrl = creator.ProfileImageUrl
            };
        }
        catch (Exception ex)
        {
            // Update video status to failed
            video.Status = VideoStatus.ProcessingFailed;
            video.ProcessingError = ex.Message;
            await _unitOfWork.Repository<Video>().UpdateAsync(video, cancellationToken);
            await _unitOfWork.SaveChangesAsync(cancellationToken);
            throw;
        }
    }
}