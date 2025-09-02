using CreatorStudio.Application.DTOs;
using CreatorStudio.Application.Features.Analytics.Queries;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CreatorStudio.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class AnalyticsController : ControllerBase
{
    private readonly IMediator _mediator;
    private readonly ILogger<AnalyticsController> _logger;

    public AnalyticsController(IMediator mediator, ILogger<AnalyticsController> logger)
    {
        _mediator = mediator;
        _logger = logger;
    }

    /// <summary>
    /// Get dashboard analytics overview for the authenticated user
    /// </summary>
    [HttpGet("dashboard")]
    public async Task<ActionResult<DashboardAnalyticsDto>> GetDashboardAnalytics(
        [FromQuery] DateTime? fromDate = null,
        [FromQuery] DateTime? toDate = null)
    {
        try
        {
            // Get user ID from claims
            var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            if (!Guid.TryParse(userIdClaim, out var userId))
            {
                return Unauthorized("Invalid user token");
            }

            var query = new GetDashboardAnalyticsQuery
            {
                UserId = userId,
                FromDate = fromDate,
                ToDate = toDate
            };

            var result = await _mediator.Send(query);
            
            if (!result.Success)
            {
                return BadRequest(result.ErrorMessage);
            }

            return Ok(result.Analytics);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting dashboard analytics");
            return StatusCode(500, "An error occurred while retrieving dashboard analytics");
        }
    }

    /// <summary>
    /// Get analytics for a specific video
    /// </summary>
    [HttpGet("videos/{videoId}")]
    public async Task<ActionResult<VideoAnalyticsDto>> GetVideoAnalytics(
        Guid videoId,
        [FromQuery] DateTime? fromDate = null,
        [FromQuery] DateTime? toDate = null)
    {
        try
        {
            // Get user ID from claims
            var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            if (!Guid.TryParse(userIdClaim, out var userId))
            {
                return Unauthorized("Invalid user token");
            }

            var query = new GetVideoAnalyticsQuery
            {
                VideoId = videoId,
                UserId = userId,
                FromDate = fromDate,
                ToDate = toDate
            };

            var result = await _mediator.Send(query);
            
            if (!result.Success)
            {
                return BadRequest(result.ErrorMessage);
            }

            return Ok(result.Analytics);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting video analytics for video {VideoId}", videoId);
            return StatusCode(500, "An error occurred while retrieving video analytics");
        }
    }

    /// <summary>
    /// Get analytics summary for all user's videos
    /// </summary>
    [HttpGet("videos")]
    public async Task<ActionResult<List<VideoAnalyticsDto>>> GetAllVideosAnalytics(
        [FromQuery] DateTime? fromDate = null,
        [FromQuery] DateTime? toDate = null)
    {
        try
        {
            // Get user ID from claims
            var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            if (!Guid.TryParse(userIdClaim, out var userId))
            {
                return Unauthorized("Invalid user token");
            }

            // Get dashboard analytics first to get video list
            var dashboardQuery = new GetDashboardAnalyticsQuery
            {
                UserId = userId,
                FromDate = fromDate,
                ToDate = toDate
            };

            var dashboardResult = await _mediator.Send(dashboardQuery);
            
            if (!dashboardResult.Success || dashboardResult.Analytics == null)
            {
                return BadRequest(dashboardResult.ErrorMessage);
            }

            // Get detailed analytics for each video
            var videoAnalytics = new List<VideoAnalyticsDto>();
            foreach (var topVideo in dashboardResult.Analytics.TopVideos)
            {
                var videoQuery = new GetVideoAnalyticsQuery
                {
                    VideoId = topVideo.Id,
                    UserId = userId,
                    FromDate = fromDate,
                    ToDate = toDate
                };

                var videoResult = await _mediator.Send(videoQuery);
                if (videoResult.Success && videoResult.Analytics != null)
                {
                    videoAnalytics.Add(videoResult.Analytics);
                }
            }

            return Ok(videoAnalytics);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting all videos analytics");
            return StatusCode(500, "An error occurred while retrieving videos analytics");
        }
    }
}