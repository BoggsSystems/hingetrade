using CreatorStudio.Domain.Entities;
using CreatorStudio.Domain.Interfaces;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace CreatorStudio.Infrastructure.Services;

public class VideoAnalyticsAggregationService : BackgroundService
{
    private readonly IServiceScopeFactory _serviceScopeFactory;
    private readonly ILogger<VideoAnalyticsAggregationService> _logger;
    private readonly TimeSpan _aggregationInterval = TimeSpan.FromHours(1); // Run every hour

    public VideoAnalyticsAggregationService(
        IServiceScopeFactory serviceScopeFactory,
        ILogger<VideoAnalyticsAggregationService> logger)
    {
        _serviceScopeFactory = serviceScopeFactory;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("Video Analytics Aggregation Service started");

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await AggregateAnalytics();
                await Task.Delay(_aggregationInterval, stoppingToken);
            }
            catch (OperationCanceledException)
            {
                // Service is stopping
                break;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in video analytics aggregation");
                // Wait 5 minutes before retrying
                await Task.Delay(TimeSpan.FromMinutes(5), stoppingToken);
            }
        }

        _logger.LogInformation("Video Analytics Aggregation Service stopped");
    }

    private async Task AggregateAnalytics()
    {
        using var scope = _serviceScopeFactory.CreateScope();
        var viewRepository = scope.ServiceProvider.GetRequiredService<IRepository<VideoView>>();
        var analyticsRepository = scope.ServiceProvider.GetRequiredService<IRepository<VideoAnalytics>>();
        var videoRepository = scope.ServiceProvider.GetRequiredService<IRepository<Video>>();
        var unitOfWork = scope.ServiceProvider.GetRequiredService<IUnitOfWork>();

        var today = DateTime.UtcNow.Date;
        var yesterday = today.AddDays(-1);

        _logger.LogInformation("Starting analytics aggregation for {Date}", yesterday);

        try
        {
            // Get all videos that had views yesterday
            var viewsYesterday = await viewRepository.FindAsync(
                v => v.CreatedAt >= yesterday && v.CreatedAt < today,
                CancellationToken.None);

            var videoGroups = viewsYesterday.GroupBy(v => v.VideoId);

            foreach (var videoGroup in videoGroups)
            {
                var videoId = videoGroup.Key;
                var views = videoGroup.ToList();

                // Check if analytics already exist for this video and date
                var existingAnalytics = await analyticsRepository.FindFirstAsync(
                    a => a.VideoId == videoId && a.Date == yesterday,
                    CancellationToken.None);

                var analytics = existingAnalytics ?? new VideoAnalytics
                {
                    Id = Guid.NewGuid(),
                    VideoId = videoId,
                    Date = yesterday
                };

                // Calculate metrics
                analytics.Views = views.Count;
                analytics.UniqueViews = views.Select(v => v.UserId ?? Guid.Parse(v.AnonymousId ?? Guid.Empty.ToString()))
                                           .Distinct()
                                           .Count();
                
                analytics.TotalWatchTimeSeconds = views.Sum(v => (long)v.WatchTimeSeconds);
                analytics.AverageWatchTimeSeconds = analytics.Views > 0 
                    ? (decimal)analytics.TotalWatchTimeSeconds / analytics.Views 
                    : 0;

                var completedViews = views.Where(v => v.CompletedView).Count();
                analytics.WatchTimePercentage = analytics.Views > 0 
                    ? (decimal)((double)completedViews / analytics.Views * 100)
                    : 0;

                analytics.Likes = views.Count(v => v.Liked);
                analytics.Shares = views.Count(v => v.Shared);
                analytics.Comments = 0; // TODO: Implement comments tracking

                analytics.EngagementRate = analytics.Views > 0 
                    ? (decimal)((double)(analytics.Likes + analytics.Shares) / analytics.Views)
                    : 0;

                // Traffic sources (placeholder - enhance based on tracking data)
                analytics.DirectTraffic = views.Count(v => string.IsNullOrEmpty(v.ReferrerUrl));
                analytics.SearchTraffic = views.Count(v => !string.IsNullOrEmpty(v.ReferrerUrl) && v.ReferrerUrl.Contains("google"));
                analytics.SocialTraffic = views.Count(v => !string.IsNullOrEmpty(v.ReferrerUrl) && 
                    (v.ReferrerUrl.Contains("facebook") || v.ReferrerUrl.Contains("twitter") || v.ReferrerUrl.Contains("tiktok")));
                analytics.ReferralTraffic = analytics.Views - analytics.DirectTraffic - analytics.SearchTraffic - analytics.SocialTraffic;

                // Geographic data (top countries)
                var topCountries = views
                    .Where(v => !string.IsNullOrEmpty(v.Country))
                    .GroupBy(v => v.Country)
                    .OrderByDescending(g => g.Count())
                    .Take(10)
                    .ToDictionary(g => g.Key!, g => g.Count());

                analytics.TopCountries = System.Text.Json.JsonSerializer.Serialize(topCountries);

                // Device types
                var deviceTypes = views
                    .Where(v => !string.IsNullOrEmpty(v.DeviceType))
                    .GroupBy(v => v.DeviceType)
                    .ToDictionary(g => g.Key!, g => g.Count());

                analytics.DeviceTypes = System.Text.Json.JsonSerializer.Serialize(deviceTypes);

                // Revenue metrics (placeholder - implement based on monetization)
                analytics.Revenue = 0;
                analytics.SubscriptionConversions = 0;
                analytics.TipRevenue = 0;

                if (existingAnalytics == null)
                {
                    await analyticsRepository.AddAsync(analytics, CancellationToken.None);
                }
                else
                {
                    await analyticsRepository.UpdateAsync(analytics, CancellationToken.None);
                }

                _logger.LogDebug("Aggregated analytics for video {VideoId}: {Views} views, {UniqueViews} unique", 
                    videoId, analytics.Views, analytics.UniqueViews);
            }

            // Update video aggregate stats
            await UpdateVideoAggregateStats(videoRepository, viewRepository);

            await unitOfWork.SaveChangesAsync(CancellationToken.None);

            _logger.LogInformation("Completed analytics aggregation for {Date}. Processed {VideoCount} videos", 
                yesterday, videoGroups.Count());
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error aggregating analytics for {Date}", yesterday);
            throw;
        }
    }

    private async Task UpdateVideoAggregateStats(
        IRepository<Video> videoRepository,
        IRepository<VideoView> viewRepository)
    {
        // Update aggregate stats for videos with recent activity
        var recentlyViewedVideos = await viewRepository.FindAsync(
            v => v.CreatedAt >= DateTime.UtcNow.AddDays(-7),
            CancellationToken.None);

        var videoIds = recentlyViewedVideos.Select(v => v.VideoId).Distinct();

        foreach (var videoId in videoIds)
        {
            var video = await videoRepository.GetByIdAsync(videoId, CancellationToken.None);
            if (video == null) continue;

            var allViews = await viewRepository.FindAsync(v => v.VideoId == videoId, CancellationToken.None);
            
            // Update aggregate stats
            video.ViewCount = allViews.Count();
            video.UniqueViewCount = allViews.Select(v => v.UserId ?? Guid.Parse(v.AnonymousId ?? Guid.Empty.ToString()))
                                           .Distinct()
                                           .Count();
            
            if (allViews.Any())
            {
                video.AverageWatchTime = (decimal)allViews.Average(v => v.WatchTimeSeconds);
                
                var engagements = allViews.Count(v => v.Liked || v.Shared);
                video.EngagementRate = video.ViewCount > 0 ? (decimal)((double)engagements / video.ViewCount) : 0;
            }

            await videoRepository.UpdateAsync(video, CancellationToken.None);
        }
    }
}