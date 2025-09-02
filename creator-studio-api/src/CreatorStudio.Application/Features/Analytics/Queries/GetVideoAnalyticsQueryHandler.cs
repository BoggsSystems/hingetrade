using CreatorStudio.Application.DTOs;
using CreatorStudio.Domain.Entities;
using CreatorStudio.Domain.Interfaces;
using MediatR;
using Microsoft.Extensions.Logging;

namespace CreatorStudio.Application.Features.Analytics.Queries;

public class GetVideoAnalyticsQueryHandler : IRequestHandler<GetVideoAnalyticsQuery, GetVideoAnalyticsResponse>
{
    private readonly IRepository<Video> _videoRepository;
    private readonly IRepository<VideoView> _viewRepository;
    private readonly ILogger<GetVideoAnalyticsQueryHandler> _logger;

    public GetVideoAnalyticsQueryHandler(
        IRepository<Video> videoRepository,
        IRepository<VideoView> viewRepository,
        ILogger<GetVideoAnalyticsQueryHandler> logger)
    {
        _videoRepository = videoRepository;
        _viewRepository = viewRepository;
        _logger = logger;
    }

    public async Task<GetVideoAnalyticsResponse> Handle(GetVideoAnalyticsQuery request, CancellationToken cancellationToken)
    {
        try
        {
            // Get the video and verify ownership
            var video = await _videoRepository.GetByIdAsync(request.VideoId, cancellationToken);
            if (video == null)
            {
                return new GetVideoAnalyticsResponse
                {
                    Success = false,
                    ErrorMessage = "Video not found"
                };
            }

            if (video.CreatorId != request.UserId)
            {
                return new GetVideoAnalyticsResponse
                {
                    Success = false,
                    ErrorMessage = "Access denied"
                };
            }

            // Get all views for this video
            var fromDate = request.FromDate ?? DateTime.UtcNow.AddDays(-30);
            var toDate = request.ToDate ?? DateTime.UtcNow;

            var views = await _viewRepository.FindAsync(
                v => v.VideoId == request.VideoId && 
                     v.CreatedAt >= fromDate && 
                     v.CreatedAt <= toDate,
                cancellationToken);

            // Calculate metrics
            var totalViews = views.Count();
            var uniqueViews = views
                .Select(v => v.UserId?.ToString() ?? v.AnonymousId ?? Guid.Empty.ToString())
                .Distinct()
                .Count();

            var totalWatchTimeSeconds = views.Sum(v => v.WatchTimeSeconds);
            var averageWatchTime = totalViews > 0 ? totalWatchTimeSeconds / (double)totalViews : 0;
            var totalWatchTimeHours = totalWatchTimeSeconds / 3600.0;

            var completedViews = views.Count(v => v.CompletedView);
            var completionRate = totalViews > 0 ? (decimal)completedViews / totalViews * 100 : 0;

            var likes = views.Count(v => v.Liked);
            var shares = views.Count(v => v.Shared);
            var engagements = likes + shares;
            var engagementRate = totalViews > 0 ? (decimal)engagements / totalViews * 100 : 0;

            // Traffic sources breakdown
            var trafficSources = views
                .Where(v => !string.IsNullOrEmpty(v.TrafficSource))
                .GroupBy(v => v.TrafficSource)
                .ToDictionary(g => g.Key!, g => g.Count());

            // Device types breakdown
            var deviceTypes = views
                .Where(v => !string.IsNullOrEmpty(v.DeviceType))
                .GroupBy(v => v.DeviceType)
                .ToDictionary(g => g.Key!, g => g.Count());

            // Daily views for the period
            var dailyViews = views
                .GroupBy(v => v.CreatedAt.Date)
                .Select(g => new DailyViewsDto
                {
                    Date = g.Key,
                    Views = g.Count(),
                    WatchTimeHours = g.Sum(v => v.WatchTimeSeconds) / 3600.0
                })
                .OrderBy(d => d.Date)
                .ToList();

            var analytics = new VideoAnalyticsDto
            {
                VideoId = video.Id,
                Title = video.Title,
                ThumbnailUrl = video.ThumbnailUrl,
                CreatedAt = video.CreatedAt,
                Views = totalViews,
                UniqueViews = uniqueViews,
                AverageWatchTimeSeconds = averageWatchTime,
                TotalWatchTimeHours = totalWatchTimeHours,
                CompletionRate = completionRate,
                EngagementRate = engagementRate,
                Likes = likes,
                Shares = shares,
                Comments = 0, // TODO: Implement when comment system exists
                TrafficSources = trafficSources,
                DeviceTypes = deviceTypes,
                DailyViews = dailyViews
            };

            return new GetVideoAnalyticsResponse
            {
                Success = true,
                Analytics = analytics
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting video analytics for video {VideoId}", request.VideoId);
            return new GetVideoAnalyticsResponse
            {
                Success = false,
                ErrorMessage = "An error occurred while retrieving video analytics"
            };
        }
    }
}