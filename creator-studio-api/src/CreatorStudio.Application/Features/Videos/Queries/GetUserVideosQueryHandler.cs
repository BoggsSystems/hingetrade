using CreatorStudio.Application.DTOs;
using CreatorStudio.Domain.Entities;
using CreatorStudio.Domain.Interfaces;
using Microsoft.AspNetCore.Identity;
using MediatR;

namespace CreatorStudio.Application.Features.Videos.Queries;

public class GetUserVideosQueryHandler : IRequestHandler<GetUserVideosQuery, GetUserVideosResponse>
{
    private readonly IRepository<Video> _videoRepository;
    private readonly UserManager<User> _userManager;

    public GetUserVideosQueryHandler(
        IRepository<Video> videoRepository,
        UserManager<User> userManager)
    {
        _videoRepository = videoRepository;
        _userManager = userManager;
    }

    public async Task<GetUserVideosResponse> Handle(GetUserVideosQuery request, CancellationToken cancellationToken)
    {
        // Get user for creator name
        var user = await _userManager.FindByIdAsync(request.UserId.ToString());
        if (user == null)
        {
            return new GetUserVideosResponse { Videos = Array.Empty<VideoDto>(), Total = 0 };
        }

        // Get videos for the user
        var videos = await _videoRepository.GetAllAsync(cancellationToken);
        var userVideos = videos.Where(v => v.CreatorId == request.UserId)
                              .OrderByDescending(v => v.CreatedAt)
                              .ToArray();

        // Convert to DTOs
        var videoDtos = userVideos.Select(video => new VideoDto
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
            CreatedAt = video.CreatedAt,
            PublishedAt = video.PublishedAt,
            IsSubscriberOnly = video.IsSubscriberOnly,
            ViewCount = video.ViewCount,
            AverageWatchTime = video.AverageWatchTime,
            EngagementRate = video.EngagementRate,
            MinimumSubscriptionTier = video.MinimumSubscriptionTier,
            CreatorDisplayName = user.FullName ?? user.Email
        }).ToArray();

        return new GetUserVideosResponse 
        { 
            Videos = videoDtos, 
            Total = videoDtos.Length 
        };
    }
}