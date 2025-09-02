using CreatorStudio.Domain.Entities;
using CreatorStudio.Domain.Interfaces;
using CreatorStudio.Domain.Services;
using MediatR;
using Microsoft.Extensions.Logging;

namespace CreatorStudio.Application.Features.Videos.Commands;

public class UpdateVideoViewCommandHandler : IRequestHandler<UpdateVideoViewCommand, UpdateVideoViewResponse>
{
    private readonly IVideoViewTrackingService _viewTrackingService;
    private readonly IRepository<VideoView> _viewRepository;
    private readonly IRepository<Video> _videoRepository;
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILogger<UpdateVideoViewCommandHandler> _logger;

    public UpdateVideoViewCommandHandler(
        IVideoViewTrackingService viewTrackingService,
        IRepository<VideoView> viewRepository,
        IRepository<Video> videoRepository,
        IUnitOfWork unitOfWork,
        ILogger<UpdateVideoViewCommandHandler> logger)
    {
        _viewTrackingService = viewTrackingService;
        _viewRepository = viewRepository;
        _videoRepository = videoRepository;
        _unitOfWork = unitOfWork;
        _logger = logger;
    }

    public async Task<UpdateVideoViewResponse> Handle(UpdateVideoViewCommand request, CancellationToken cancellationToken)
    {
        try
        {
            // Get the view session
            var videoView = await _viewRepository.GetByIdAsync(request.SessionId, cancellationToken);
            if (videoView == null)
            {
                return new UpdateVideoViewResponse
                {
                    Success = false,
                    ErrorMessage = "View session not found",
                    SessionExpired = true
                };
            }

            // Check if session is expired (30 minutes)
            var sessionAge = DateTime.UtcNow - videoView.CreatedAt;
            if (sessionAge.TotalMinutes > 30)
            {
                _logger.LogWarning("View session {SessionId} has expired", request.SessionId);
                return new UpdateVideoViewResponse
                {
                    Success = false,
                    ErrorMessage = "Session expired",
                    SessionExpired = true
                };
            }

            // Update watch progress
            var success = await _viewTrackingService.UpdateViewProgressAsync(
                request.SessionId,
                request.WatchTimeSeconds,
                request.MaxWatchTimeSeconds,
                cancellationToken);

            if (!success)
            {
                return new UpdateVideoViewResponse
                {
                    Success = false,
                    ErrorMessage = "Failed to update view progress"
                };
            }

            // Update the VideoView record
            videoView.WatchTimeSeconds = (int)request.WatchTimeSeconds;
            videoView.MaxWatchTimeSeconds = Math.Max(videoView.MaxWatchTimeSeconds, (int)request.MaxWatchTimeSeconds);
            videoView.WatchPercentage = (decimal)request.WatchPercentage;
            videoView.LastWatchedAt = DateTime.UtcNow;

            // Mark as completed if watched 80% or more
            if (request.WatchPercentage >= 80 && !videoView.CompletedView)
            {
                videoView.CompletedView = true;
                _logger.LogInformation("Video view {SessionId} marked as completed", request.SessionId);
            }

            await _viewRepository.UpdateAsync(videoView, cancellationToken);

            // Update video's average watch time periodically (every 10th update)
            if (videoView.Id.GetHashCode() % 10 == 0)
            {
                var video = await _videoRepository.GetByIdAsync(videoView.VideoId, cancellationToken);
                if (video != null)
                {
                    // Get recent views to calculate average
                    var recentViews = (await _viewRepository.FindAsync(
                        v => v.VideoId == videoView.VideoId && v.CreatedAt > DateTime.UtcNow.AddDays(-7),
                        cancellationToken)).Take(100);

                    if (recentViews.Any())
                    {
                        video.AverageWatchTime = (decimal)recentViews.Average(v => v.WatchTimeSeconds);
                        await _videoRepository.UpdateAsync(video, cancellationToken);
                    }
                }
            }

            await _unitOfWork.SaveChangesAsync(cancellationToken);

            return new UpdateVideoViewResponse
            {
                Success = true
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating video view session {SessionId}", request.SessionId);
            return new UpdateVideoViewResponse
            {
                Success = false,
                ErrorMessage = "An error occurred while updating the view session"
            };
        }
    }
}