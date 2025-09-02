using CreatorStudio.Domain.Entities;
using CreatorStudio.Domain.Events;
using CreatorStudio.Domain.Interfaces;
using CreatorStudio.Domain.Services;
using MediatR;
using Microsoft.Extensions.Logging;

namespace CreatorStudio.Application.Features.Videos.Commands;

public class CompleteVideoViewCommandHandler : IRequestHandler<CompleteVideoViewCommand, CompleteVideoViewResponse>
{
    private readonly IVideoViewTrackingService _viewTrackingService;
    private readonly IRepository<VideoView> _viewRepository;
    private readonly IRepository<Video> _videoRepository;
    private readonly IUnitOfWork _unitOfWork;
    private readonly IMediator _mediator;
    private readonly ILogger<CompleteVideoViewCommandHandler> _logger;

    public CompleteVideoViewCommandHandler(
        IVideoViewTrackingService viewTrackingService,
        IRepository<VideoView> viewRepository,
        IRepository<Video> videoRepository,
        IUnitOfWork unitOfWork,
        IMediator mediator,
        ILogger<CompleteVideoViewCommandHandler> logger)
    {
        _viewTrackingService = viewTrackingService;
        _viewRepository = viewRepository;
        _videoRepository = videoRepository;
        _unitOfWork = unitOfWork;
        _mediator = mediator;
        _logger = logger;
    }

    public async Task<CompleteVideoViewResponse> Handle(CompleteVideoViewCommand request, CancellationToken cancellationToken)
    {
        try
        {
            // Get the view session
            var videoView = await _viewRepository.GetByIdAsync(request.SessionId, cancellationToken);
            if (videoView == null)
            {
                return new CompleteVideoViewResponse
                {
                    Success = false,
                    ErrorMessage = "View session not found"
                };
            }

            // Complete the view session
            var success = await _viewTrackingService.CompleteViewSessionAsync(
                request.SessionId,
                request.FinalWatchTimeSeconds,
                request.Completed,
                cancellationToken);

            if (!success)
            {
                return new CompleteVideoViewResponse
                {
                    Success = false,
                    ErrorMessage = "Failed to complete view session"
                };
            }

            // Update the VideoView record
            videoView.WatchTimeSeconds = (int)request.FinalWatchTimeSeconds;
            videoView.MaxWatchTimeSeconds = Math.Max(videoView.MaxWatchTimeSeconds, (int)request.MaxWatchTimeSeconds);
            videoView.WatchPercentage = videoView.Video?.DurationSeconds > 0 
                ? (decimal)((request.FinalWatchTimeSeconds / videoView.Video.DurationSeconds.Value) * 100)
                : 0;
            videoView.CompletedView = request.Completed || videoView.WatchPercentage >= 80;
            videoView.LastWatchedAt = DateTime.UtcNow;

            // Update engagement
            if (request.Liked.HasValue)
            {
                videoView.Liked = request.Liked.Value;
                await _viewTrackingService.RecordViewEngagementAsync(
                    request.SessionId,
                    request.Liked.Value,
                    request.Shared,
                    cancellationToken);
            }

            if (request.Shared.HasValue)
            {
                videoView.Shared = request.Shared.Value;
            }

            await _viewRepository.UpdateAsync(videoView, cancellationToken);

            // Get the video to update engagement metrics
            var video = await _videoRepository.GetByIdAsync(videoView.VideoId, cancellationToken);
            if (video != null)
            {
                // Update engagement rate
                var totalEngagements = await _viewRepository.CountAsync(
                    v => v.VideoId == video.Id && (v.Liked || v.Shared),
                    cancellationToken);
                
                video.EngagementRate = video.ViewCount > 0 
                    ? (decimal)((double)totalEngagements / video.ViewCount)
                    : 0;

                // Update unique view count if this is a new unique viewer
                var isUniqueView = await _viewRepository.CountAsync(
                    v => v.VideoId == video.Id && 
                         v.Id != videoView.Id &&
                         ((v.UserId.HasValue && v.UserId == videoView.UserId) ||
                          (!v.UserId.HasValue && v.AnonymousId == videoView.AnonymousId)),
                    cancellationToken) == 0;

                if (isUniqueView)
                {
                    video.UniqueViewCount++;
                }

                await _videoRepository.UpdateAsync(video, cancellationToken);

                // Publish domain event
                await _mediator.Publish(new VideoViewedEvent(
                    video.Id,
                    video.CreatorId,
                    videoView.UserId,
                    (int)request.FinalWatchTimeSeconds,
                    (decimal)videoView.WatchPercentage
                ), cancellationToken);
            }

            await _unitOfWork.SaveChangesAsync(cancellationToken);

            _logger.LogInformation("Completed view session {SessionId} for video {VideoId}. Watch time: {WatchTime}s, Completed: {Completed}", 
                request.SessionId, videoView.VideoId, request.FinalWatchTimeSeconds, request.Completed);

            return new CompleteVideoViewResponse
            {
                Success = true,
                Summary = new VideoViewSummary
                {
                    TotalWatchTimeSeconds = request.FinalWatchTimeSeconds,
                    CompletionRate = (double)videoView.WatchPercentage,
                    WasLiked = videoView.Liked,
                    WasShared = videoView.Shared,
                    UpdatedViewCount = (int)(video?.ViewCount ?? 0)
                }
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error completing video view session {SessionId}", request.SessionId);
            return new CompleteVideoViewResponse
            {
                Success = false,
                ErrorMessage = "An error occurred while completing the view session"
            };
        }
    }
}