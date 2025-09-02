using CreatorStudio.Application.DTOs;
using CreatorStudio.Domain.Entities;
using CreatorStudio.Domain.Interfaces;
using CreatorStudio.Domain.Enums;
using Microsoft.AspNetCore.Identity;
using MediatR;

namespace CreatorStudio.Application.Features.Videos.Queries;

public class GetPublicFeedQueryHandler : IRequestHandler<GetPublicFeedQuery, PublicFeedResponse>
{
    private readonly IRepository<Video> _videoRepository;
    private readonly IRepository<VideoView> _viewRepository;
    private readonly IRepository<Subscription> _subscriptionRepository;
    private readonly UserManager<User> _userManager;

    public GetPublicFeedQueryHandler(
        IRepository<Video> videoRepository,
        IRepository<VideoView> viewRepository,
        IRepository<Subscription> subscriptionRepository,
        UserManager<User> userManager)
    {
        _videoRepository = videoRepository;
        _viewRepository = viewRepository;
        _subscriptionRepository = subscriptionRepository;
        _userManager = userManager;
    }

    public async Task<PublicFeedResponse> Handle(GetPublicFeedQuery request, CancellationToken cancellationToken)
    {
        // Get all public videos
        var allVideos = await _videoRepository.FindAsync(
            v => v.Visibility == VideoVisibility.Public && 
                 v.Status == VideoStatus.Published, 
            cancellationToken);

        // Filter by symbol if specified
        if (!string.IsNullOrEmpty(request.Symbol))
        {
            allVideos = allVideos.Where(v => v.TradingSymbols != null && 
                                           v.TradingSymbols.Contains(request.Symbol, StringComparer.OrdinalIgnoreCase));
        }

        // Apply feed algorithm based on type
        var orderedVideos = request.FeedType.ToLower() switch
        {
            "trending" => await ApplyTrendingAlgorithm(allVideos, cancellationToken),
            "newest" => allVideos.OrderByDescending(v => v.PublishedAt ?? v.CreatedAt),
            "most_viewed" => allVideos.OrderByDescending(v => v.ViewCount),
            "educational" => allVideos.Where(v => v.Tags != null && 
                                                v.Tags.Any(t => t.Contains("education", StringComparison.OrdinalIgnoreCase) ||
                                                              t.Contains("tutorial", StringComparison.OrdinalIgnoreCase) ||
                                                              t.Contains("analysis", StringComparison.OrdinalIgnoreCase)))
                                    .OrderByDescending(v => v.EngagementRate),
            _ => await ApplyPersonalizedAlgorithm(allVideos, cancellationToken) // Default to personalized
        };

        var totalCount = orderedVideos.Count();
        
        // Apply pagination
        var paginatedVideos = orderedVideos
            .Skip((request.Page - 1) * request.PageSize)
            .Take(request.PageSize)
            .ToArray();

        // Convert to DTOs with creator info
        var videoDtos = new List<VideoDto>();
        
        foreach (var video in paginatedVideos)
        {
            var user = await _userManager.FindByIdAsync(video.CreatorId.ToString());
            
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
                CreatorDisplayName = user?.FullName ?? user?.Email ?? "Unknown Creator"
            });
        }

        return new PublicFeedResponse
        {
            Videos = videoDtos.ToArray(),
            Total = totalCount,
            Page = request.Page,
            PageSize = request.PageSize,
            HasMore = (request.Page * request.PageSize) < totalCount,
            FeedType = request.FeedType
        };
    }

    private async Task<IEnumerable<Video>> ApplyTrendingAlgorithm(IEnumerable<Video> videos, CancellationToken cancellationToken)
    {
        var cutoffTime = DateTime.UtcNow.AddHours(-24);
        
        // Get recent views for trending calculation
        var recentViews = await _viewRepository.FindAsync(
            v => v.LastWatchedAt >= cutoffTime, 
            cancellationToken);

        var recentViewsByVideo = recentViews
            .GroupBy(v => v.VideoId)
            .ToDictionary(g => g.Key, g => g.Count());

        return videos.OrderByDescending(v => 
        {
            var recentViewCount = recentViewsByVideo.GetValueOrDefault(v.Id, 0);
            var engagementRate = v.EngagementRate;
            var totalViews = v.ViewCount;
            
            // Trending score: recent views * 2 + engagement rate * 100 + total views * 0.1
            return (recentViewCount * 2) + ((double)engagementRate * 100) + (totalViews * 0.1);
        });
    }

    private async Task<IEnumerable<Video>> ApplyPersonalizedAlgorithm(IEnumerable<Video> videos, CancellationToken cancellationToken)
    {
        // For now, use a simple algorithm based on engagement rate and recency
        // In a real implementation, this would use user viewing history and preferences
        
        var now = DateTime.UtcNow;
        
        return videos.OrderByDescending(v => 
        {
            var daysSincePublished = (now - (v.PublishedAt ?? v.CreatedAt)).TotalDays;
            var recencyScore = Math.Max(0, 7 - daysSincePublished) / 7.0; // Higher score for newer videos
            var engagementScore = v.EngagementRate;
            var viewScore = Math.Log10(v.ViewCount + 1) / 10.0; // Logarithmic view count
            
            return (recencyScore * 0.4) + ((double)engagementScore * 0.4) + (viewScore * 0.2);
        });
    }
}