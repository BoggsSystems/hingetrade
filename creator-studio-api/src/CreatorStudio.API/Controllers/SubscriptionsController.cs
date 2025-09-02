using CreatorStudio.Application.Features.Subscriptions.Commands;
using CreatorStudio.Application.Features.Subscriptions.Queries;
using MediatR;
using Microsoft.AspNetCore.Mvc;

namespace CreatorStudio.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class SubscriptionsController : ControllerBase
{
    private readonly IMediator _mediator;
    private readonly ILogger<SubscriptionsController> _logger;

    public SubscriptionsController(IMediator mediator, ILogger<SubscriptionsController> logger)
    {
        _mediator = mediator;
        _logger = logger;
    }

    /// <summary>
    /// Follow a creator
    /// </summary>
    [HttpPost("{userId}/follow/{creatorId}")]
    public async Task<ActionResult> FollowCreator(Guid userId, Guid creatorId, CancellationToken cancellationToken = default)
    {
        try
        {
            var command = new FollowCreatorCommand(userId, creatorId);
            var result = await _mediator.Send(command, cancellationToken);
            
            return result ? NoContent() : BadRequest("Failed to follow creator");
        }
        catch (ArgumentException ex)
        {
            _logger.LogWarning(ex, "Invalid follow request for user {UserId} and creator {CreatorId}", userId, creatorId);
            return BadRequest(ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error following creator {CreatorId} for user {UserId}", creatorId, userId);
            return StatusCode(500, "An error occurred while following the creator");
        }
    }

    /// <summary>
    /// Unfollow a creator
    /// </summary>
    [HttpDelete("{userId}/follow/{creatorId}")]
    public async Task<ActionResult> UnfollowCreator(Guid userId, Guid creatorId, CancellationToken cancellationToken = default)
    {
        try
        {
            var command = new UnfollowCreatorCommand(userId, creatorId);
            var result = await _mediator.Send(command, cancellationToken);
            
            return result ? NoContent() : NotFound("Subscription not found");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error unfollowing creator {CreatorId} for user {UserId}", creatorId, userId);
            return StatusCode(500, "An error occurred while unfollowing the creator");
        }
    }

    /// <summary>
    /// Get user's subscriptions
    /// </summary>
    [HttpGet("{userId}")]
    public async Task<ActionResult<UserSubscriptionsResponse>> GetUserSubscriptions(
        Guid userId, 
        CancellationToken cancellationToken = default)
    {
        try
        {
            var query = new GetUserSubscriptionsQuery(userId);
            var result = await _mediator.Send(query, cancellationToken);
            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching subscriptions for user {UserId}", userId);
            return StatusCode(500, "An error occurred while fetching subscriptions");
        }
    }

    /// <summary>
    /// Check if user is following a creator
    /// </summary>
    [HttpGet("{userId}/following/{creatorId}")]
    public async Task<ActionResult<FollowingStatusResponse>> GetFollowingStatus(
        Guid userId, 
        Guid creatorId, 
        CancellationToken cancellationToken = default)
    {
        try
        {
            var query = new GetFollowingStatusQuery(userId, creatorId);
            var result = await _mediator.Send(query, cancellationToken);
            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error checking following status for user {UserId} and creator {CreatorId}", userId, creatorId);
            return StatusCode(500, "An error occurred while checking following status");
        }
    }
}