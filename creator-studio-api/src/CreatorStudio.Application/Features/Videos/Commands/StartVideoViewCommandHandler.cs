using CreatorStudio.Domain.Entities;
using CreatorStudio.Domain.Interfaces;
using CreatorStudio.Domain.Services;
using MediatR;
using Microsoft.Extensions.Logging;

namespace CreatorStudio.Application.Features.Videos.Commands;

public class StartVideoViewCommandHandler : IRequestHandler<StartVideoViewCommand, StartVideoViewResponse>
{
    private readonly IVideoViewTrackingService _viewTrackingService;
    private readonly IRepository<Video> _videoRepository;
    private readonly IRepository<VideoView> _viewRepository;
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILogger<StartVideoViewCommandHandler> _logger;

    public StartVideoViewCommandHandler(
        IVideoViewTrackingService viewTrackingService,
        IRepository<Video> videoRepository,
        IRepository<VideoView> viewRepository,
        IUnitOfWork unitOfWork,
        ILogger<StartVideoViewCommandHandler> logger)
    {
        _viewTrackingService = viewTrackingService;
        _videoRepository = videoRepository;
        _viewRepository = viewRepository;
        _unitOfWork = unitOfWork;
        _logger = logger;
    }

    public async Task<StartVideoViewResponse> Handle(StartVideoViewCommand request, CancellationToken cancellationToken)
    {
        try
        {
            // Get the video
            var video = await _videoRepository.GetByIdAsync(request.VideoId, cancellationToken);
            if (video == null)
            {
                return new StartVideoViewResponse
                {
                    Success = false,
                    ErrorMessage = "Video not found"
                };
            }

            // Use the user ID from the request (set by the API layer)
            var userId = request.UserId;

            var ipAddress = request.IpAddress;
            var userAgent = request.UserAgent;

            // Validate the session (basic fraud prevention)
            var isValid = await _viewTrackingService.ValidateViewSessionAsync(
                request.VideoId, 
                ipAddress, 
                userAgent, 
                userId, 
                cancellationToken);

            if (!isValid)
            {
                _logger.LogWarning("Invalid view session attempt for video {VideoId} from IP {IpAddress}", 
                    request.VideoId, ipAddress);
                return new StartVideoViewResponse
                {
                    Success = false,
                    ErrorMessage = "Invalid session"
                };
            }

            // Start the view session
            var sessionId = await _viewTrackingService.StartViewSessionAsync(
                request.VideoId,
                userId,
                request.AnonymousId,
                ipAddress,
                userAgent,
                cancellationToken);

            // Create the initial VideoView record
            var videoView = new VideoView
            {
                Id = sessionId,
                VideoId = request.VideoId,
                UserId = userId,
                AnonymousId = request.AnonymousId ?? Guid.NewGuid().ToString(),
                IpAddress = ipAddress,
                UserAgent = userAgent,
                Country = request.Country,
                City = request.City,
                DeviceType = request.DeviceType,
                TrafficSource = request.TrafficSource,
                WatchTimeSeconds = 0,
                MaxWatchTimeSeconds = 0,
                WatchPercentage = 0,
                CompletedView = false,
                LastWatchedAt = DateTime.UtcNow
            };

            await _viewRepository.AddAsync(videoView, cancellationToken);

            // Increment view count immediately
            video.ViewCount++;
            await _videoRepository.UpdateAsync(video, cancellationToken);
            
            await _unitOfWork.SaveChangesAsync(cancellationToken);

            _logger.LogInformation("Started view session {SessionId} for video {VideoId}", sessionId, request.VideoId);

            return new StartVideoViewResponse
            {
                SessionId = sessionId,
                Success = true,
                VideoDurationSeconds = video.DurationSeconds
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error starting video view session for video {VideoId}", request.VideoId);
            return new StartVideoViewResponse
            {
                Success = false,
                ErrorMessage = "An error occurred while starting the view session"
            };
        }
    }
}