using CreatorStudio.Application.DTOs;
using CreatorStudio.Domain.Entities;
using CreatorStudio.Domain.Enums;
using CreatorStudio.Domain.Interfaces;
using MediatR;
using Microsoft.Extensions.Logging;

namespace CreatorStudio.Application.Features.Analytics.Queries;

public class GetDashboardAnalyticsQueryHandler : IRequestHandler<GetDashboardAnalyticsQuery, GetDashboardAnalyticsResponse>
{
    private readonly IRepository<Video> _videoRepository;
    private readonly IRepository<VideoView> _viewRepository;
    private readonly ILogger<GetDashboardAnalyticsQueryHandler> _logger;

    public GetDashboardAnalyticsQueryHandler(
        IRepository<Video> videoRepository,
        IRepository<VideoView> viewRepository,
        ILogger<GetDashboardAnalyticsQueryHandler> logger)
    {
        _videoRepository = videoRepository;
        _viewRepository = viewRepository;
        _logger = logger;
    }

    public async Task<GetDashboardAnalyticsResponse> Handle(GetDashboardAnalyticsQuery request, CancellationToken cancellationToken)
    {
        try
        {
            // Get user's videos
            var userVideos = await _videoRepository.FindAsync(
                v => v.CreatorId == request.UserId,
                cancellationToken);

            var publishedVideos = userVideos.Where(v => v.Status == VideoStatus.Published).ToList();
            var videoIds = publishedVideos.Select(v => v.Id).ToList();

            // Get all views for user's videos
            var allViewsCollection = await _viewRepository.FindAsync(
                v => videoIds.Contains(v.VideoId),
                cancellationToken);
            var allViews = allViewsCollection.ToList();

            var currentMonth = DateTime.UtcNow.Date.AddDays(-DateTime.UtcNow.Day + 1);
            var lastMonth = currentMonth.AddMonths(-1);
            var thisMonthViews = allViews.Where(v => v.CreatedAt >= currentMonth).ToList();
            var lastMonthViews = allViews.Where(v => v.CreatedAt >= lastMonth && v.CreatedAt < currentMonth).ToList();

            // Calculate metrics
            var totalViews = allViews.Count;
            var uniqueViews = allViews
                .Select(v => v.UserId?.ToString() ?? v.AnonymousId ?? Guid.Empty.ToString())
                .Distinct()
                .Count();

            var totalWatchTimeSeconds = allViews.Sum(v => v.WatchTimeSeconds);
            var totalWatchTimeHours = totalWatchTimeSeconds / 3600.0;

            var thisMonthWatchTime = thisMonthViews.Sum(v => v.WatchTimeSeconds) / 3600.0;
            var lastMonthWatchTime = lastMonthViews.Sum(v => v.WatchTimeSeconds) / 3600.0;

            // Calculate growth percentages
            var viewsGrowthPercentage = CalculateGrowthPercentage(thisMonthViews.Count(), lastMonthViews.Count());
            var watchTimeGrowthPercentage = CalculateGrowthPercentage(thisMonthWatchTime, lastMonthWatchTime);

            // Get top videos
            var topVideos = publishedVideos
                .Select(v => new TopVideoDto
                {
                    Id = v.Id,
                    Title = v.Title,
                    ThumbnailUrl = v.ThumbnailUrl,
                    Views = v.ViewCount,
                    WatchTimeHours = (double)(v.AverageWatchTime * v.ViewCount) / 3600,
                    EngagementRate = v.EngagementRate
                })
                .OrderByDescending(v => v.Views)
                .Take(5)
                .ToList();

            var analytics = new DashboardAnalyticsDto
            {
                TotalVideos = userVideos.Count(),
                PublishedVideos = publishedVideos.Count,
                TotalViews = totalViews,
                UniqueViews = uniqueViews,
                TotalWatchTimeHours = totalWatchTimeHours,
                Subscribers = 0, // TODO: Implement when subscription system exists
                Revenue = 0, // TODO: Implement when monetization exists
                MonthlyGrowthPercentage = viewsGrowthPercentage,
                ThisMonth = new MonthlyAnalyticsDto
                {
                    Views = thisMonthViews.Count(),
                    WatchTimeHours = thisMonthWatchTime,
                    Revenue = 0, // TODO: Implement
                    ViewsGrowthPercentage = viewsGrowthPercentage,
                    WatchTimeGrowthPercentage = watchTimeGrowthPercentage,
                    RevenueGrowthPercentage = 0 // TODO: Implement
                },
                TopVideos = topVideos
            };

            return new GetDashboardAnalyticsResponse
            {
                Success = true,
                Analytics = analytics
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting dashboard analytics for user {UserId}", request.UserId);
            return new GetDashboardAnalyticsResponse
            {
                Success = false,
                ErrorMessage = "An error occurred while retrieving analytics"
            };
        }
    }

    private static decimal CalculateGrowthPercentage(int current, int previous)
    {
        if (previous == 0)
            return current > 0 ? 100 : 0;
        
        return (decimal)((current - previous) / (double)previous * 100);
    }

    private static decimal CalculateGrowthPercentage(double current, double previous)
    {
        if (previous == 0)
            return current > 0 ? 100 : 0;
        
        return (decimal)((current - previous) / previous * 100);
    }
}