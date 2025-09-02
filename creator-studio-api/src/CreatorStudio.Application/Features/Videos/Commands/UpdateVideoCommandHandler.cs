using CreatorStudio.Application.DTOs;
using CreatorStudio.Domain.Entities;
using CreatorStudio.Domain.Interfaces;
using Microsoft.AspNetCore.Identity;
using MediatR;

namespace CreatorStudio.Application.Features.Videos.Commands;

public class UpdateVideoCommandHandler : IRequestHandler<UpdateVideoCommand, VideoDto?>
{
    private readonly IRepository<Video> _videoRepository;
    private readonly UserManager<User> _userManager;
    private readonly IUnitOfWork _unitOfWork;

    public UpdateVideoCommandHandler(
        IRepository<Video> videoRepository,
        UserManager<User> userManager,
        IUnitOfWork unitOfWork)
    {
        _videoRepository = videoRepository;
        _userManager = userManager;
        _unitOfWork = unitOfWork;
    }

    public async Task<VideoDto?> Handle(UpdateVideoCommand request, CancellationToken cancellationToken)
    {
        var video = await _videoRepository.GetByIdAsync(request.VideoId, cancellationToken);
        
        if (video == null)
        {
            return null;
        }

        // Update video properties if provided
        if (!string.IsNullOrEmpty(request.UpdateDto.Title))
        {
            video.Title = request.UpdateDto.Title;
        }

        if (request.UpdateDto.Description != null)
        {
            video.Description = request.UpdateDto.Description;
        }

        if (request.UpdateDto.Visibility.HasValue)
        {
            video.Visibility = request.UpdateDto.Visibility.Value;
        }

        if (request.UpdateDto.Tags != null)
        {
            video.Tags = request.UpdateDto.Tags;
        }

        if (request.UpdateDto.IsSubscriberOnly.HasValue)
        {
            video.IsSubscriberOnly = request.UpdateDto.IsSubscriberOnly.Value;
        }

        if (request.UpdateDto.MinimumSubscriptionTier.HasValue)
        {
            video.MinimumSubscriptionTier = request.UpdateDto.MinimumSubscriptionTier.Value;
        }

        if (request.UpdateDto.PurchasePrice.HasValue)
        {
            video.PurchasePrice = request.UpdateDto.PurchasePrice.Value;
        }

        if (request.UpdateDto.ScheduledAt.HasValue)
        {
            video.ScheduledAt = request.UpdateDto.ScheduledAt.Value;
        }

        video.UpdatedAt = DateTime.UtcNow;

        // Save changes
        await _videoRepository.UpdateAsync(video, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        // Get creator info for response
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