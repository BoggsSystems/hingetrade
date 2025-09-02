using CreatorStudio.Application.DTOs;
using CreatorStudio.Domain.Entities;
using CreatorStudio.Domain.Interfaces;
using CreatorStudio.Domain.Enums;
using Microsoft.AspNetCore.Identity;
using MediatR;

namespace CreatorStudio.Application.Features.Videos.Queries;

public class GetVideosBySymbolQueryHandler : IRequestHandler<GetVideosBySymbolQuery, VideosBySymbolResponse>
{
    private readonly IRepository<Video> _videoRepository;
    private readonly UserManager<User> _userManager;

    public GetVideosBySymbolQueryHandler(
        IRepository<Video> videoRepository,
        UserManager<User> userManager)
    {
        _videoRepository = videoRepository;
        _userManager = userManager;
    }

    public async Task<VideosBySymbolResponse> Handle(GetVideosBySymbolQuery request, CancellationToken cancellationToken)
    {
        // Get all public videos that mention the symbol
        var symbolVideos = await _videoRepository.FindAsync(
            v => v.Visibility == VideoVisibility.Public && 
                 v.Status == VideoStatus.Published &&
                 v.TradingSymbols != null &&
                 v.TradingSymbols.Contains(request.Symbol, StringComparer.OrdinalIgnoreCase),
            cancellationToken);

        // Apply sorting based on sortBy parameter
        var sortedVideos = request.SortBy.ToLower() switch
        {
            "newest" => symbolVideos.OrderByDescending(v => v.PublishedAt ?? v.CreatedAt),
            "oldest" => symbolVideos.OrderBy(v => v.PublishedAt ?? v.CreatedAt),
            "most_viewed" => symbolVideos.OrderByDescending(v => v.ViewCount),
            "least_viewed" => symbolVideos.OrderBy(v => v.ViewCount),
            "highest_engagement" => symbolVideos.OrderByDescending(v => v.EngagementRate),
            "longest" => symbolVideos.OrderByDescending(v => v.DurationSeconds ?? 0),
            "shortest" => symbolVideos.OrderBy(v => v.DurationSeconds ?? 0),
            "trending" => ApplyTrendingSortForSymbol(symbolVideos),
            "educational" => symbolVideos
                .Where(v => v.Tags != null && 
                          v.Tags.Any(t => t.Contains("education", StringComparison.OrdinalIgnoreCase) ||
                                        t.Contains("tutorial", StringComparison.OrdinalIgnoreCase) ||
                                        t.Contains("analysis", StringComparison.OrdinalIgnoreCase) ||
                                        t.Contains("fundamentals", StringComparison.OrdinalIgnoreCase)))
                .OrderByDescending(v => v.EngagementRate)
                .Concat(symbolVideos
                    .Where(v => v.Tags == null || 
                              !v.Tags.Any(t => t.Contains("education", StringComparison.OrdinalIgnoreCase) ||
                                             t.Contains("tutorial", StringComparison.OrdinalIgnoreCase) ||
                                             t.Contains("analysis", StringComparison.OrdinalIgnoreCase) ||
                                             t.Contains("fundamentals", StringComparison.OrdinalIgnoreCase)))
                    .OrderByDescending(v => v.PublishedAt ?? v.CreatedAt)),
            "technical" => symbolVideos
                .Where(v => v.Tags != null && 
                          v.Tags.Any(t => t.Contains("technical", StringComparison.OrdinalIgnoreCase) ||
                                        t.Contains("chart", StringComparison.OrdinalIgnoreCase) ||
                                        t.Contains("pattern", StringComparison.OrdinalIgnoreCase) ||
                                        t.Contains("indicator", StringComparison.OrdinalIgnoreCase)))
                .OrderByDescending(v => v.EngagementRate)
                .Concat(symbolVideos
                    .Where(v => v.Tags == null || 
                              !v.Tags.Any(t => t.Contains("technical", StringComparison.OrdinalIgnoreCase) ||
                                             t.Contains("chart", StringComparison.OrdinalIgnoreCase) ||
                                             t.Contains("pattern", StringComparison.OrdinalIgnoreCase) ||
                                             t.Contains("indicator", StringComparison.OrdinalIgnoreCase)))
                    .OrderByDescending(v => v.PublishedAt ?? v.CreatedAt)),
            _ => symbolVideos.OrderByDescending(v => v.PublishedAt ?? v.CreatedAt) // Default to newest
        };

        var totalCount = sortedVideos.Count();

        // Apply pagination
        var paginatedVideos = sortedVideos
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

        return new VideosBySymbolResponse
        {
            Videos = videoDtos.ToArray(),
            Total = totalCount,
            Page = request.Page,
            PageSize = request.PageSize,
            HasMore = (request.Page * request.PageSize) < totalCount,
            Symbol = request.Symbol,
            SortBy = request.SortBy
        };
    }

    private IOrderedEnumerable<Video> ApplyTrendingSortForSymbol(IEnumerable<Video> videos)
    {
        var now = DateTime.UtcNow;
        
        return videos.OrderByDescending(v => 
        {
            var hoursAge = (now - (v.PublishedAt ?? v.CreatedAt)).TotalHours;
            var viewVelocity = v.ViewCount / Math.Max(1, hoursAge);
            var engagementRate = v.EngagementRate;
            var recencyBoost = Math.Max(0.1, Math.Exp(-hoursAge / 24.0)); // 24-hour half-life
            
            return (viewVelocity * 0.4) + ((double)engagementRate * 0.4) + (recencyBoost * 0.2);
        });
    }
}