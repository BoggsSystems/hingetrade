using CreatorStudio.Application.DTOs;
using CreatorStudio.Domain.Entities;
using CreatorStudio.Domain.Interfaces;
using Microsoft.AspNetCore.Identity;
using MediatR;

namespace CreatorStudio.Application.Features.Videos.Queries;

public class GetVideoByIdQueryHandler : IRequestHandler<GetVideoByIdQuery, VideoDto?>
{
    private readonly IRepository<Video> _videoRepository;
    private readonly UserManager<User> _userManager;

    public GetVideoByIdQueryHandler(
        IRepository<Video> videoRepository,
        UserManager<User> userManager)
    {
        _videoRepository = videoRepository;
        _userManager = userManager;
    }

    public async Task<VideoDto?> Handle(GetVideoByIdQuery request, CancellationToken cancellationToken)
    {
        var video = await _videoRepository.GetByIdAsync(request.VideoId, cancellationToken);
        
        if (video == null)
        {
            return null;
        }

        // Get creator info
        var user = await _userManager.FindByIdAsync(video.CreatorId.ToString());

        return new VideoDto
        {
            Id = video.Id,
            CreatorId = video.CreatorId,
            Title = video.Title,
            Description = video.Description,
            ThumbnailUrl = video.ThumbnailUrl,
            VideoUrl = video.VideoUrl,
            Status = video.Status,
            Visibility = video.Visibility,
            DurationSeconds = video.DurationSeconds,
            FileSizeBytes = video.FileSizeBytes,
            Tags = video.Tags,
            TradingSymbols = video.TradingSymbols,
            CreatedAt = video.CreatedAt,
            PublishedAt = video.PublishedAt,
            ScheduledAt = video.ScheduledAt,
            IsSubscriberOnly = video.IsSubscriberOnly,
            ViewCount = video.ViewCount,
            AverageWatchTime = video.AverageWatchTime,
            EngagementRate = video.EngagementRate,
            MinimumSubscriptionTier = video.MinimumSubscriptionTier,
            PurchasePrice = video.PurchasePrice,
            CreatorDisplayName = user?.FullName ?? user?.Email ?? "Unknown Creator",
            CreatorProfileImageUrl = user?.ProfileImageUrl,
            HasTranscription = !string.IsNullOrEmpty(video.TranscriptionText)
        };
    }
}