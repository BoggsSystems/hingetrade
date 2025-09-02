using CreatorStudio.Application.DTOs;
using CreatorStudio.Domain.Entities;
using CreatorStudio.Domain.Interfaces;
using CreatorStudio.Domain.Enums;
using CreatorStudio.Domain.Services;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Logging;
using MediatR;

namespace CreatorStudio.Application.Features.Videos.Commands;

public class PublishVideoCommandHandler : IRequestHandler<PublishVideoCommand, VideoDto?>
{
    private readonly IRepository<Video> _videoRepository;
    private readonly UserManager<User> _userManager;
    private readonly IUnitOfWork _unitOfWork;
    private readonly IVideoStatusService _statusService;
    private readonly ILogger<PublishVideoCommandHandler> _logger;

    public PublishVideoCommandHandler(
        IRepository<Video> videoRepository,
        UserManager<User> userManager,
        IUnitOfWork unitOfWork,
        IVideoStatusService statusService,
        ILogger<PublishVideoCommandHandler> logger)
    {
        _videoRepository = videoRepository;
        _userManager = userManager;
        _unitOfWork = unitOfWork;
        _statusService = statusService;
        _logger = logger;
    }

    public async Task<VideoDto?> Handle(PublishVideoCommand request, CancellationToken cancellationToken)
    {
        try
        {
            var video = await _videoRepository.GetByIdAsync(request.VideoId, cancellationToken);
            
            if (video == null)
            {
                _logger.LogWarning("Video not found: {VideoId}", request.VideoId);
                return null;
            }

            // Use the status service to publish
            var success = await _statusService.PublishVideoAsync(video);
            if (!success)
            {
                _logger.LogError("Failed to publish video {VideoId}", request.VideoId);
                throw new InvalidOperationException("Failed to publish video");
            }

            // Extract trading symbols from title and description if not already set
            if (video.TradingSymbols == null || !video.TradingSymbols.Any())
            {
                video.TradingSymbols = ExtractTradingSymbols(video.Title, video.Description);
            }

            // Save changes
            await _videoRepository.UpdateAsync(video, cancellationToken);
            await _unitOfWork.SaveChangesAsync(cancellationToken);

            _logger.LogInformation("Video {VideoId} published successfully", request.VideoId);

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
                HasTranscription = !string.IsNullOrEmpty(video.TranscriptionText),
                IsFromFollowedCreator = false,
                UserSubscriptionTier = null,
                TrendingScore = null
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error publishing video {VideoId}", request.VideoId);
            throw;
        }
    }

    private string[] ExtractTradingSymbols(string title, string? description)
    {
        var symbols = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        var content = $"{title} {description ?? ""}";
        
        // Simple regex pattern to match stock symbols (3-5 uppercase letters)
        var symbolPattern = @"\b[A-Z]{1,5}\b";
        var matches = System.Text.RegularExpressions.Regex.Matches(content, symbolPattern);
        
        foreach (System.Text.RegularExpressions.Match match in matches)
        {
            var symbol = match.Value;
            
            // Filter out common words that aren't likely to be stock symbols
            if (!IsCommonWord(symbol) && symbol.Length >= 1 && symbol.Length <= 5)
            {
                symbols.Add(symbol);
            }
        }
        
        // Also look for symbols with $ prefix
        var dollarSymbolPattern = @"\$[A-Z]{1,5}\b";
        var dollarMatches = System.Text.RegularExpressions.Regex.Matches(content, dollarSymbolPattern);
        
        foreach (System.Text.RegularExpressions.Match match in dollarMatches)
        {
            var symbol = match.Value.Substring(1); // Remove $ prefix
            symbols.Add(symbol);
        }
        
        return symbols.ToArray();
    }
    
    private bool IsCommonWord(string word)
    {
        var commonWords = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
        {
            "THE", "AND", "FOR", "ARE", "BUT", "NOT", "YOU", "ALL", "CAN", "HER", "WAS", "ONE", "OUR",
            "HAD", "BUT", "WORDS", "NOT", "WHAT", "ALL", "WERE", "THEY", "WE", "WHEN", "YOUR", "CAN",
            "SAID", "THERE", "EACH", "WHICH", "DO", "HOW", "THEIR", "IF", "WILL", "UP", "OTHER", "ABOUT",
            "OUT", "MANY", "THEN", "THEM", "THESE", "SO", "SOME", "HER", "WOULD", "MAKE", "LIKE", "INTO",
            "HIM", "HAS", "TWO", "MORE", "HER", "GO", "NO", "WAY", "COULD", "MY", "THAN", "FIRST", "BEEN",
            "CALL", "WHO", "ITS", "NOW", "FIND", "LONG", "DOWN", "DAY", "DID", "GET", "COME", "MADE", "MAY",
            "PART", "OVER", "NEW", "SOUND", "TAKE", "ONLY", "LITTLE", "WORK", "KNOW", "PLACE", "YEAR", "LIVE",
            "ME", "BACK", "GIVE", "MOST", "VERY", "AFTER", "THINGS", "OUR", "JUST", "NAME", "GOOD", "SENTENCE",
            "MAN", "THINK", "SAY", "GREAT", "WHERE", "HELP", "THROUGH", "MUCH", "BEFORE", "LINE", "RIGHT", "TOO",
            "MEAN", "OLD", "ANY", "SAME", "TELL", "BOY", "FOLLOW", "CAME", "WANT", "SHOW", "ALSO", "AROUND",
            "FORM", "THREE", "SMALL", "SET", "PUT", "END", "WHY", "AGAIN", "TURN", "HERE", "OFF", "WENT",
            "CAME", "ALSO", "AFTER", "BACK", "OTHER", "MANY", "THAN", "THEN", "THEM", "THESE", "SO", "SOME"
        };
        
        return commonWords.Contains(word);
    }
}