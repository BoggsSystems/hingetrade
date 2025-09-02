using CreatorStudio.Application.DTOs;
using CreatorStudio.Domain.Entities;
using CreatorStudio.Domain.Interfaces;
using CreatorStudio.Domain.Enums;
using Microsoft.AspNetCore.Identity;
using MediatR;

namespace CreatorStudio.Application.Features.Videos.Queries;

public class GetTrendingVideosQueryHandler : IRequestHandler<GetTrendingVideosQuery, TrendingVideosResponse>
{
    private readonly IRepository<Video> _videoRepository;
    private readonly IRepository<VideoView> _viewRepository;
    private readonly IRepository<VideoAnalytics> _analyticsRepository;
    private readonly UserManager<User> _userManager;

    public GetTrendingVideosQueryHandler(
        IRepository<Video> videoRepository,
        IRepository<VideoView> viewRepository,
        IRepository<VideoAnalytics> analyticsRepository,
        UserManager<User> userManager)
    {
        _videoRepository = videoRepository;
        _viewRepository = viewRepository;
        _analyticsRepository = analyticsRepository;
        _userManager = userManager;
    }

    public async Task<TrendingVideosResponse> Handle(GetTrendingVideosQuery request, CancellationToken cancellationToken)
    {
        var cutoffTime = DateTime.UtcNow.AddHours(-request.Hours);

        // Get all public videos
        var allVideos = await _videoRepository.FindAsync(
            v => v.Visibility == VideoVisibility.Public && 
                 v.Status == VideoStatus.Published &&
                 (v.PublishedAt ?? v.CreatedAt) >= cutoffTime.AddDays(-7), // Only consider videos from last week for trending
            cancellationToken);

        // Filter by symbol if specified
        if (!string.IsNullOrEmpty(request.Symbol))
        {
            allVideos = allVideos.Where(v => v.TradingSymbols != null && 
                                           v.TradingSymbols.Contains(request.Symbol, StringComparer.OrdinalIgnoreCase));
        }

        // Get recent views and analytics for trending calculation
        var recentViews = await _viewRepository.FindAsync(
            v => v.LastWatchedAt >= cutoffTime, 
            cancellationToken);

        var recentAnalytics = await _analyticsRepository.FindAsync(
            a => a.Date >= cutoffTime,
            cancellationToken);

        // Calculate trending scores
        var videoTrendingScores = await CalculateTrendingScores(allVideos, recentViews, recentAnalytics, request.Hours);

        // Sort by trending score
        var trendingVideos = videoTrendingScores
            .OrderByDescending(kvp => kvp.Value)
            .Select(kvp => kvp.Key);

        var totalCount = trendingVideos.Count();

        // Apply pagination
        var paginatedVideos = trendingVideos
            .Skip((request.Page - 1) * request.PageSize)
            .Take(request.PageSize)
            .ToArray();

        // Convert to DTOs with creator info and trending metadata
        var videoDtos = new List<VideoDto>();
        
        foreach (var video in paginatedVideos)
        {
            var user = await _userManager.FindByIdAsync(video.CreatorId.ToString());
            var trendingScore = videoTrendingScores[video];
            
            videoDtos.Add(new VideoDto
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
                IsSubscriberOnly = video.IsSubscriberOnly,
                ViewCount = video.ViewCount,
                AverageWatchTime = video.AverageWatchTime,
                EngagementRate = video.EngagementRate,
                MinimumSubscriptionTier = video.MinimumSubscriptionTier,
                CreatorDisplayName = user?.FullName ?? user?.Email ?? "Unknown Creator",
                TrendingScore = trendingScore
            });
        }

        return new TrendingVideosResponse
        {
            Videos = videoDtos.ToArray(),
            Total = totalCount,
            Page = request.Page,
            PageSize = request.PageSize,
            HasMore = (request.Page * request.PageSize) < totalCount,
            Hours = request.Hours
        };
    }

    private async Task<Dictionary<Video, double>> CalculateTrendingScores(
        IEnumerable<Video> videos, 
        IEnumerable<VideoView> recentViews, 
        IEnumerable<VideoAnalytics> recentAnalytics,
        int hours)
    {
        var scores = new Dictionary<Video, double>();
        
        // Group views and analytics by video
        var viewsByVideo = recentViews
            .GroupBy(v => v.VideoId)
            .ToDictionary(g => g.Key, g => g.ToList());

        var analyticsByVideo = recentAnalytics
            .GroupBy(a => a.VideoId)
            .ToDictionary(g => g.Key, g => g.ToList());

        foreach (var video in videos)
        {
            var videoViews = viewsByVideo.GetValueOrDefault(video.Id, new List<VideoView>());
            var videoAnalytics = analyticsByVideo.GetValueOrDefault(video.Id, new List<VideoAnalytics>());

            // Calculate various trending factors
            var recentViewCount = videoViews.Count;
            var uniqueViewers = videoViews.Select(v => v.UserId).Distinct().Count();
            var avgWatchTime = videoViews.Any() ? videoViews.Average(v => v.WatchTimeSeconds) : 0;
            var completionRate = video.DurationSeconds > 0 && avgWatchTime > 0 ? 
                Math.Min(1.0, avgWatchTime / video.DurationSeconds.Value) : 0;

            // Recent engagement from analytics
            var recentLikes = videoAnalytics.Sum(a => a.Likes);
            var recentShares = videoAnalytics.Sum(a => a.Shares);
            var recentComments = videoAnalytics.Sum(a => a.Comments);

            // Video age factor (newer videos get slight boost)
            var ageInHours = (DateTime.UtcNow - (video.PublishedAt ?? video.CreatedAt)).TotalHours;
            var ageFactor = Math.Max(0.1, Math.Exp(-ageInHours / (hours * 2.0))); // Exponential decay

            // Calculate trending score
            var velocityScore = recentViewCount * 1.0; // Raw view velocity
            var engagementScore = (recentLikes * 3) + (recentShares * 5) + (recentComments * 2); // Weighted engagement
            var qualityScore = completionRate * uniqueViewers * 2; // Quality based on completion and unique viewers
            var diversityScore = uniqueViewers > 0 ? (double)uniqueViewers / recentViewCount : 0; // Viewer diversity
            
            var trendingScore = (velocityScore * 0.3) + 
                               (engagementScore * 0.3) + 
                               (qualityScore * 0.2) + 
                               (diversityScore * 100 * 0.1) + 
                               (ageFactor * 50 * 0.1); // Age boost

            scores[video] = trendingScore;
        }

        return scores;
    }
}