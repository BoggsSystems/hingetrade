using CreatorStudio.Application.DTOs;
using CreatorStudio.Domain.Entities;
using CreatorStudio.Domain.Interfaces;
using CreatorStudio.Domain.Services;
using MediatR;
using Microsoft.Extensions.Logging;

namespace CreatorStudio.Application.Features.Videos.Commands;

public class UnpublishVideoCommandHandler : IRequestHandler<UnpublishVideoCommand, VideoDto?>
{
    private readonly IRepository<Video> _videoRepository;
    private readonly IVideoStatusService _statusService;
    private readonly ILogger<UnpublishVideoCommandHandler> _logger;

    public UnpublishVideoCommandHandler(
        IRepository<Video> videoRepository,
        IVideoStatusService statusService,
        ILogger<UnpublishVideoCommandHandler> logger)
    {
        _videoRepository = videoRepository;
        _statusService = statusService;
        _logger = logger;
    }

    public async Task<VideoDto?> Handle(UnpublishVideoCommand request, CancellationToken cancellationToken)
    {
        try
        {
            var video = await _videoRepository.GetByIdAsync(request.VideoId, cancellationToken);
            if (video == null)
            {
                _logger.LogWarning("Video not found: {VideoId}", request.VideoId);
                return null;
            }

            // Use the status service to unpublish
            var success = await _statusService.UnpublishVideoAsync(video, request.Reason);
            if (!success)
            {
                _logger.LogError("Failed to unpublish video {VideoId}", request.VideoId);
                throw new InvalidOperationException("Failed to unpublish video");
            }

            await _videoRepository.UpdateAsync(video, cancellationToken);

            _logger.LogInformation("Video {VideoId} unpublished successfully", request.VideoId);

            // Return updated video DTO
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
                CreatorDisplayName = video.User?.Email ?? "Unknown Creator", // User doesn't have DisplayName property
                CreatorProfileImageUrl = video.User?.ProfileImageUrl,
                IsFromFollowedCreator = false,
                UserSubscriptionTier = null,
                TrendingScore = null
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error unpublishing video {VideoId}", request.VideoId);
            throw;
        }
    }
}