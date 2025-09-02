using CreatorStudio.Application.DTOs;
using CreatorStudio.Domain.Entities;
using CreatorStudio.Domain.Interfaces;
using CreatorStudio.Domain.Enums;
using Microsoft.AspNetCore.Identity;
using MediatR;

namespace CreatorStudio.Application.Features.Videos.Queries;

public class GetFollowingFeedQueryHandler : IRequestHandler<GetFollowingFeedQuery, FollowingFeedResponse>
{
    private readonly IRepository<Video> _videoRepository;
    private readonly IRepository<Subscription> _subscriptionRepository;
    private readonly UserManager<User> _userManager;

    public GetFollowingFeedQueryHandler(
        IRepository<Video> videoRepository,
        IRepository<Subscription> subscriptionRepository,
        UserManager<User> userManager)
    {
        _videoRepository = videoRepository;
        _subscriptionRepository = subscriptionRepository;
        _userManager = userManager;
    }

    public async Task<FollowingFeedResponse> Handle(GetFollowingFeedQuery request, CancellationToken cancellationToken)
    {
        // Get all active subscriptions for the user
        var userSubscriptions = await _subscriptionRepository.FindAsync(
            s => s.UserId == request.UserId && s.IsActive,
            cancellationToken);

        var followedCreatorIds = userSubscriptions.Select(s => s.CreatorId).ToHashSet();
        var followingCount = followedCreatorIds.Count;

        if (followingCount == 0)
        {
            return new FollowingFeedResponse
            {
                Videos = Array.Empty<VideoDto>(),
                Total = 0,
                Page = request.Page,
                PageSize = request.PageSize,
                HasMore = false,
                FollowingCount = 0
            };
        }

        // Get all public videos from followed creators
        var followingVideos = await _videoRepository.FindAsync(
            v => v.Visibility == VideoVisibility.Public && 
                 v.Status == VideoStatus.Published &&
                 followedCreatorIds.Contains(v.CreatorId),
            cancellationToken);

        // Include subscriber-only content if user has appropriate subscription
        var subscriberOnlyVideos = await _videoRepository.FindAsync(
            v => v.Visibility == VideoVisibility.Public && 
                 v.Status == VideoStatus.Published &&
                 v.IsSubscriberOnly &&
                 followedCreatorIds.Contains(v.CreatorId),
            cancellationToken);

        // Filter subscriber-only videos based on user's subscription tiers
        var accessibleSubscriberVideos = new List<Video>();
        foreach (var video in subscriberOnlyVideos)
        {
            var userSubscription = userSubscriptions.FirstOrDefault(s => s.CreatorId == video.CreatorId);
            if (userSubscription != null && 
                (video.MinimumSubscriptionTier == null || 
                 userSubscription.Tier >= video.MinimumSubscriptionTier))
            {
                accessibleSubscriberVideos.Add(video);
            }
        }

        // Combine all accessible videos
        var allAccessibleVideos = followingVideos.Concat(accessibleSubscriberVideos).Distinct();

        // Sort by publication date (most recent first) with some creator diversity
        var sortedVideos = ApplyFollowingFeedAlgorithm(allAccessibleVideos, userSubscriptions);

        var totalCount = sortedVideos.Count();

        // Apply pagination
        var paginatedVideos = sortedVideos
            .Skip((request.Page - 1) * request.PageSize)
            .Take(request.PageSize)
            .ToArray();

        // Convert to DTOs with creator info and subscription status
        var videoDtos = new List<VideoDto>();
        
        foreach (var video in paginatedVideos)
        {
            var user = await _userManager.FindByIdAsync(video.CreatorId.ToString());
            var userSubscription = userSubscriptions.FirstOrDefault(s => s.CreatorId == video.CreatorId);
            
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
                UserSubscriptionTier = userSubscription?.Tier,
                IsFromFollowedCreator = true
            });
        }

        return new FollowingFeedResponse
        {
            Videos = videoDtos.ToArray(),
            Total = totalCount,
            Page = request.Page,
            PageSize = request.PageSize,
            HasMore = (request.Page * request.PageSize) < totalCount,
            FollowingCount = followingCount
        };
    }

    private IEnumerable<Video> ApplyFollowingFeedAlgorithm(IEnumerable<Video> videos, IEnumerable<Subscription> subscriptions)
    {
        var now = DateTime.UtcNow;
        var subscriptionsByCreator = subscriptions.ToDictionary(s => s.CreatorId, s => s);
        var videosByCreator = videos.GroupBy(v => v.CreatorId).ToDictionary(g => g.Key, g => g.OrderByDescending(v => v.PublishedAt ?? v.CreatedAt).ToList());

        // Interleave videos from different creators to provide diversity
        var result = new List<Video>();
        var creatorQueues = videosByCreator.ToDictionary(
            kvp => kvp.Key, 
            kvp => new Queue<Video>(kvp.Value)
        );

        // Priority boost for premium subscriptions
        var creatorPriorities = subscriptionsByCreator.ToDictionary(
            kvp => kvp.Key,
            kvp => kvp.Value.Tier switch
            {
                SubscriptionTier.Premium => 3.0,
                SubscriptionTier.VIP => 2.0,
                SubscriptionTier.Basic => 1.0,
                _ => 1.0
            }
        );

        // Round-robin through creators with priority weighting
        while (creatorQueues.Any(q => q.Value.Count > 0))
        {
            var availableCreators = creatorQueues.Where(kvp => kvp.Value.Count > 0).ToList();
            
            // Weighted selection based on subscription tier
            foreach (var creatorQueue in availableCreators.OrderByDescending(kvp => 
                creatorPriorities.GetValueOrDefault(kvp.Key, 1.0) * 
                Random.Shared.NextDouble())) // Add some randomness
            {
                if (creatorQueue.Value.Count > 0)
                {
                    var video = creatorQueue.Value.Dequeue();
                    result.Add(video);
                    
                    // Limit consecutive videos from same creator (except for premium subscriptions)
                    var priority = creatorPriorities.GetValueOrDefault(creatorQueue.Key, 1.0);
                    if (priority < 2.0) // Only for Basic subscribers
                    {
                        break; // Move to next creator
                    }
                    
                    // Premium/Pro subscribers can have up to 2-3 consecutive videos
                    var maxConsecutive = priority >= 3.0 ? 3 : 2;
                    for (int i = 1; i < maxConsecutive && creatorQueue.Value.Count > 0; i++)
                    {
                        if (Random.Shared.NextDouble() < 0.5) break; // 50% chance to continue
                        result.Add(creatorQueue.Value.Dequeue());
                    }
                    break;
                }
            }
        }

        return result;
    }
}