using CreatorStudio.Application.DTOs;
using CreatorStudio.Application.Features.Videos.Commands;
using CreatorStudio.Application.Features.Videos.Queries;
using CreatorStudio.API.Models;
using CreatorStudio.Domain.Services;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CreatorStudio.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class VideosController : ControllerBase
{
    private readonly IMediator _mediator;
    private readonly ILogger<VideosController> _logger;

    public VideosController(IMediator mediator, ILogger<VideosController> logger)
    {
        _mediator = mediator;
        _logger = logger;
    }

    /// <summary>
    /// Upload a new video
    /// </summary>
    /// <param name="creatorId">The ID of the creator uploading the video</param>
    /// <param name="file">The video file</param>
    /// <param name="title">Video title</param>
    /// <param name="description">Video description (optional)</param>
    /// <param name="visibility">Video visibility setting</param>
    /// <param name="tags">Comma-separated tags (optional)</param>
    /// <param name="isSubscriberOnly">Whether video requires subscription</param>
    /// <param name="cancellationToken">Cancellation token</param>
    /// <returns>The uploaded video details</returns>
    [HttpPost("upload")]
    [DisableRequestSizeLimit]
    public async Task<ActionResult<VideoDto>> UploadVideo(
        [FromForm] Guid creatorId,
        [FromForm] IFormFile file,
        [FromForm] string title,
        [FromForm] string? description = null,
        [FromForm] string visibility = "Public",
        [FromForm] string? tags = null,
        [FromForm] bool isSubscriberOnly = false,
        CancellationToken cancellationToken = default)
    {
        if (file == null || file.Length == 0)
        {
            return BadRequest("No file uploaded");
        }

        // Validate file type
        var allowedExtensions = new[] { ".mp4", ".mov", ".avi", ".webm", ".mkv" };
        var fileExtension = Path.GetExtension(file.FileName).ToLowerInvariant();
        
        if (!allowedExtensions.Contains(fileExtension))
        {
            return BadRequest($"File type {fileExtension} is not supported. Allowed types: {string.Join(", ", allowedExtensions)}");
        }

        // Validate file size (max 2GB for now)
        const long maxFileSize = 2L * 1024 * 1024 * 1024; // 2GB
        if (file.Length > maxFileSize)
        {
            return BadRequest("File size exceeds 2GB limit");
        }

        try
        {
            using var stream = file.OpenReadStream();
            
            var videoData = new CreateVideoDto
            {
                Title = title,
                Description = description,
                Visibility = Enum.TryParse<Domain.Enums.VideoVisibility>(visibility, out var vis) 
                    ? vis : Domain.Enums.VideoVisibility.Public,
                Tags = !string.IsNullOrWhiteSpace(tags) 
                    ? tags.Split(',', StringSplitOptions.RemoveEmptyEntries).Select(t => t.Trim()).ToArray() 
                    : null,
                IsSubscriberOnly = isSubscriberOnly
            };

            var command = new UploadVideoCommand(creatorId, stream, file.FileName, videoData);
            var result = await _mediator.Send(command, cancellationToken);

            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            _logger.LogWarning(ex, "Invalid request for video upload");
            return BadRequest(ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error uploading video");
            return StatusCode(500, "An error occurred while uploading the video");
        }
    }

    /// <summary>
    /// Get video processing status
    /// </summary>
    [HttpGet("{videoId}/status")]
    public async Task<ActionResult> GetVideoStatus(Guid videoId)
    {
        // TODO: Implement get video status query
        return Ok(new { status = "Not implemented yet" });
    }

    /// <summary>
    /// Get video details
    /// </summary>
    [HttpGet("{videoId}")]
    public async Task<ActionResult<VideoDto>> GetVideo(Guid videoId)
    {
        try
        {
            var query = new GetVideoByIdQuery(videoId);
            var result = await _mediator.Send(query);
            
            if (result == null)
            {
                return NotFound($"Video with ID {videoId} not found");
            }
            
            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching video {VideoId}", videoId);
            return StatusCode(500, "An error occurred while fetching the video");
        }
    }

    /// <summary>
    /// Get videos for a user
    /// </summary>
    [HttpGet]
    public async Task<ActionResult<GetUserVideosResponse>> GetVideos([FromQuery] Guid userId)
    {
        try
        {
            var query = new GetUserVideosQuery(userId);
            var result = await _mediator.Send(query);
            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching videos for user {UserId}", userId);
            return StatusCode(500, "An error occurred while fetching videos");
        }
    }

    /// <summary>
    /// Save video metadata after Cloudinary upload
    /// </summary>
    [HttpPost]
    public async Task<ActionResult<VideoDto>> SaveVideoMetadata([FromBody] SaveVideoMetadataDto videoMetadata)
    {
        try
        {
            var command = new SaveVideoMetadataCommand(videoMetadata);
            var result = await _mediator.Send(command);
            return CreatedAtAction(nameof(GetVideo), new { videoId = result.Id }, result);
        }
        catch (ArgumentException ex)
        {
            _logger.LogWarning(ex, "Invalid video metadata");
            return BadRequest(ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error saving video metadata");
            return StatusCode(500, "An error occurred while saving video metadata");
        }
    }

    /// <summary>
    /// Get videos for a creator
    /// </summary>
    [HttpGet("creator/{creatorId}")]
    public async Task<ActionResult<IEnumerable<VideoDto>>> GetCreatorVideos(Guid creatorId)
    {
        try
        {
            var query = new GetUserVideosQuery(creatorId);
            var result = await _mediator.Send(query);
            return Ok(result.Videos);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching videos for creator {CreatorId}", creatorId);
            return StatusCode(500, "An error occurred while fetching creator videos");
        }
    }

    /// <summary>
    /// Update video details
    /// </summary>
    [HttpPut("{videoId}")]
    public async Task<ActionResult<VideoDto>> UpdateVideo(Guid videoId, [FromBody] UpdateVideoDto updateDto)
    {
        try
        {
            var command = new UpdateVideoCommand(videoId, updateDto);
            var result = await _mediator.Send(command);
            
            if (result == null)
            {
                return NotFound($"Video with ID {videoId} not found");
            }
            
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            _logger.LogWarning(ex, "Invalid update request for video {VideoId}", videoId);
            return BadRequest(ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating video {VideoId}", videoId);
            return StatusCode(500, "An error occurred while updating the video");
        }
    }

    /// <summary>
    /// Delete a video
    /// </summary>
    [HttpDelete("{videoId}")]
    public async Task<ActionResult> DeleteVideo(Guid videoId)
    {
        try
        {
            var command = new DeleteVideoCommand(videoId);
            var result = await _mediator.Send(command);
            
            if (!result)
            {
                return NotFound($"Video with ID {videoId} not found");
            }
            
            return NoContent();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting video {VideoId}", videoId);
            return StatusCode(500, "An error occurred while deleting the video");
        }
    }

    /// <summary>
    /// Publish a video (ReadyToPublish -> Published)
    /// </summary>
    [HttpPost("{videoId}/publish")]
    public async Task<ActionResult> PublishVideo(Guid videoId)
    {
        try
        {
            var command = new PublishVideoCommand(videoId);
            var result = await _mediator.Send(command);
            
            if (result == null)
            {
                return NotFound($"Video with ID {videoId} not found");
            }
            
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            _logger.LogWarning(ex, "Invalid publish request for video {VideoId}", videoId);
            return BadRequest(ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error publishing video {VideoId}", videoId);
            return StatusCode(500, "An error occurred while publishing the video");
        }
    }

    /// <summary>
    /// Unpublish a video (Published -> Unpublished)
    /// </summary>
    [HttpPost("{videoId}/unpublish")]
    public async Task<ActionResult> UnpublishVideo(Guid videoId, [FromBody] UnpublishVideoRequest? request = null)
    {
        try
        {
            var command = new UnpublishVideoCommand(videoId, request?.Reason);
            var result = await _mediator.Send(command);
            
            if (result == null)
            {
                return NotFound($"Video with ID {videoId} not found");
            }
            
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            _logger.LogWarning(ex, "Invalid unpublish request for video {VideoId}", videoId);
            return BadRequest(ex.Message);
        }
        catch (InvalidOperationException ex)
        {
            _logger.LogWarning(ex, "Cannot unpublish video {VideoId}", videoId);
            return BadRequest(ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error unpublishing video {VideoId}", videoId);
            return StatusCode(500, "An error occurred while unpublishing the video");
        }
    }

    /// <summary>
    /// Re-publish an unpublished video (Unpublished -> Published)
    /// </summary>
    [HttpPost("{videoId}/republish")]
    public async Task<ActionResult> RepublishVideo(Guid videoId)
    {
        try
        {
            var command = new PublishVideoCommand(videoId); // Reuse publish command
            var result = await _mediator.Send(command);
            
            if (result == null)
            {
                return NotFound($"Video with ID {videoId} not found");
            }
            
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            _logger.LogWarning(ex, "Invalid republish request for video {VideoId}", videoId);
            return BadRequest(ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error republishing video {VideoId}", videoId);
            return StatusCode(500, "An error occurred while republishing the video");
        }
    }

    /// <summary>
    /// Get public video feed for TikTok-style experience
    /// </summary>
    [HttpGet("public/feed")]
    public async Task<ActionResult<IEnumerable<VideoDto>>> GetPublicFeed(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        [FromQuery] string? symbol = null,
        [FromQuery] string feedType = "personalized")
    {
        try
        {
            var query = new GetPublicFeedQuery(page, pageSize, symbol, feedType);
            var result = await _mediator.Send(query);
            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching public video feed");
            return StatusCode(500, "An error occurred while fetching video feed");
        }
    }

    /// <summary>
    /// Get trending videos
    /// </summary>
    [HttpGet("public/trending")]
    public async Task<ActionResult<IEnumerable<VideoDto>>> GetTrendingVideos(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        [FromQuery] string? symbol = null,
        [FromQuery] int hours = 24)
    {
        try
        {
            var query = new GetTrendingVideosQuery(page, pageSize, symbol, hours);
            var result = await _mediator.Send(query);
            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching trending videos");
            return StatusCode(500, "An error occurred while fetching trending videos");
        }
    }

    /// <summary>
    /// Get videos by trading symbol
    /// </summary>
    [HttpGet("public/symbol/{symbol}")]
    public async Task<ActionResult<IEnumerable<VideoDto>>> GetVideosBySymbol(
        string symbol,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        [FromQuery] string sortBy = "newest")
    {
        try
        {
            var query = new GetVideosBySymbolQuery(symbol, page, pageSize, sortBy);
            var result = await _mediator.Send(query);
            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching videos for symbol {Symbol}", symbol);
            return StatusCode(500, "An error occurred while fetching videos");
        }
    }

    /// <summary>
    /// Get videos from followed creators
    /// </summary>
    [HttpGet("public/following/{userId}")]
    public async Task<ActionResult<IEnumerable<VideoDto>>> GetFollowingFeed(
        Guid userId,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        try
        {
            var query = new GetFollowingFeedQuery(userId, page, pageSize);
            var result = await _mediator.Send(query);
            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching following feed for user {UserId}", userId);
            return StatusCode(500, "An error occurred while fetching following feed");
        }
    }

    #region View Tracking Endpoints

    /// <summary>
    /// Start a video view session
    /// </summary>
    [HttpPost("{id}/views/start")]
    public async Task<ActionResult<StartVideoViewResponse>> StartViewSession(
        Guid id,
        [FromBody] StartVideoViewCommand command)
    {
        if (command.VideoId != id)
        {
            command.VideoId = id;
        }

        // Set user ID if authenticated
        if (User.Identity?.IsAuthenticated == true)
        {
            var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            if (Guid.TryParse(userIdClaim, out var userId))
            {
                command.UserId = userId;
            }
        }

        // Get client info if not provided
        if (string.IsNullOrEmpty(command.IpAddress))
        {
            command.IpAddress = HttpContext.Connection.RemoteIpAddress?.ToString();
        }

        if (string.IsNullOrEmpty(command.UserAgent))
        {
            command.UserAgent = Request.Headers["User-Agent"].ToString();
        }

        var result = await _mediator.Send(command);
        if (!result.Success)
        {
            return BadRequest(result);
        }

        return Ok(result);
    }

    /// <summary>
    /// Update video view progress
    /// </summary>
    [HttpPut("{id}/views/{sessionId}")]
    public async Task<ActionResult<UpdateVideoViewResponse>> UpdateViewProgress(
        Guid id,
        Guid sessionId,
        [FromBody] UpdateVideoViewCommand command)
    {
        if (command.SessionId != sessionId)
        {
            command.SessionId = sessionId;
        }

        var result = await _mediator.Send(command);
        if (!result.Success)
        {
            if (result.SessionExpired)
            {
                return StatusCode(410, result); // Gone
            }
            return BadRequest(result);
        }

        return Ok(result);
    }

    /// <summary>
    /// Complete a video view session
    /// </summary>
    [HttpPost("{id}/views/complete")]
    public async Task<ActionResult<CompleteVideoViewResponse>> CompleteViewSession(
        Guid id,
        [FromBody] CompleteVideoViewCommand command)
    {
        var result = await _mediator.Send(command);
        if (!result.Success)
        {
            return BadRequest(result);
        }

        return Ok(result);
    }

    /// <summary>
    /// Get video view statistics
    /// </summary>
    [HttpGet("{id}/stats")]
    [Authorize]
    public async Task<ActionResult<VideoViewStats>> GetVideoStats(Guid id)
    {
        try
        {
            var video = await _mediator.Send(new GetVideoByIdQuery(id));
            if (video == null)
            {
                return NotFound();
            }

            // Check if user is the creator
            var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            if (video.CreatorId.ToString() != userId)
            {
                return Forbid("You can only view stats for your own videos");
            }

            var trackingService = HttpContext.RequestServices.GetRequiredService<IVideoViewTrackingService>();
            var stats = await trackingService.GetVideoViewStatsAsync(id);
            
            return Ok(stats);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching video stats for {VideoId}", id);
            return StatusCode(500, "An error occurred while fetching video statistics");
        }
    }

    #endregion
}