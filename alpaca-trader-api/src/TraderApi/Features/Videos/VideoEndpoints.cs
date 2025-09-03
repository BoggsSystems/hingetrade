using System.Security.Claims;
using Microsoft.AspNetCore.Http.HttpResults;
using FluentValidation;

namespace TraderApi.Features.Videos;

public static class VideoEndpoints
{
    public static void MapVideoEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/videos")
            .RequireAuthorization()
            .WithTags("Videos");

        // Get personalized video feed
        group.MapGet("/feed", GetVideoFeed)
            .WithName("GetVideoFeed")
            .WithSummary("Get personalized video feed for the user")
            .WithDescription("Returns a paginated feed of videos personalized for the authenticated user")
            .Produces<VideoFeedResponse>()
            .Produces(400)
            .Produces(401);

        // Get videos by stock symbol
        group.MapGet("/by-symbol/{symbol}", GetVideosBySymbol)
            .WithName("GetVideosBySymbol")
            .WithSummary("Get videos mentioning a specific stock symbol")
            .WithDescription("Returns videos that mention or analyze the specified stock symbol")
            .Produces<VideoFeedResponse>()
            .Produces(400)
            .Produces(401);

        // Get trending videos
        group.MapGet("/trending", GetTrendingVideos)
            .WithName("GetTrendingVideos")
            .WithSummary("Get trending videos")
            .WithDescription("Returns currently trending videos in the trading community")
            .Produces<VideoFeedResponse>()
            .Produces(401);

        // Get specific video
        group.MapGet("/{videoId:guid}", GetVideo)
            .WithName("GetVideo")
            .WithSummary("Get a specific video by ID")
            .WithDescription("Returns detailed information about a specific video")
            .Produces<VideoDto>()
            .Produces(404)
            .Produces(401);

        // Record video interaction (like, save, share)
        group.MapPost("/{videoId:guid}/interactions", RecordVideoInteraction)
            .WithName("RecordVideoInteraction")
            .WithSummary("Record user interaction with video")
            .WithDescription("Records user interactions like likes, saves, or shares")
            .Produces(204)
            .Produces(400)
            .Produces(401);

        // Get creator profile
        group.MapGet("/creators/{creatorId:guid}", GetCreator)
            .WithName("GetCreator")
            .WithSummary("Get creator profile information")
            .WithDescription("Returns detailed information about a video creator")
            .Produces<CreatorDto>()
            .Produces(404)
            .Produces(401);

        // Follow/unfollow creator
        group.MapPost("/creators/{creatorId:guid}/follow", FollowCreator)
            .WithName("FollowCreator")
            .WithSummary("Follow or unfollow a creator")
            .WithDescription("Adds or removes a creator from the user's following list")
            .Produces(204)
            .Produces(400)
            .Produces(401);
    }

    private static async Task<Results<Ok<VideoFeedResponse>, BadRequest<string>, UnauthorizedHttpResult>> GetVideoFeed(
        ClaimsPrincipal user,
        IVideoService videoService,
        IValidator<VideoFeedRequest> validator,
        int page = 1,
        int pageSize = 20,
        VideoFeedType feedType = VideoFeedType.Personalized,
        string? symbol = null,
        bool? followingOnly = null,
        CancellationToken cancellationToken = default)
    {
        var userId = GetUserId(user);
        if (userId == null)
            return TypedResults.Unauthorized();

        var request = new VideoFeedRequest(page, pageSize, feedType, symbol, followingOnly);
        var validationResult = await validator.ValidateAsync(request, cancellationToken);
        
        if (!validationResult.IsValid)
        {
            return TypedResults.BadRequest(string.Join(", ", validationResult.Errors.Select(e => e.ErrorMessage)));
        }

        try
        {
            var response = await videoService.GetVideoFeedAsync(userId.Value, request, cancellationToken);
            return TypedResults.Ok(response);
        }
        catch (VideoServiceException ex)
        {
            return TypedResults.BadRequest(ex.Message);
        }
    }

    private static async Task<Results<Ok<VideoFeedResponse>, BadRequest<string>, UnauthorizedHttpResult>> GetVideosBySymbol(
        string symbol,
        ClaimsPrincipal user,
        IVideoService videoService,
        int page = 1,
        int pageSize = 20,
        CancellationToken cancellationToken = default)
    {
        var userId = GetUserId(user);
        if (userId == null)
            return TypedResults.Unauthorized();

        if (string.IsNullOrWhiteSpace(symbol) || symbol.Length > 5)
        {
            return TypedResults.BadRequest("Invalid symbol format");
        }

        try
        {
            var request = new VideoFeedRequest(page, pageSize, VideoFeedType.SymbolBased, symbol.ToUpperInvariant());
            var response = await videoService.GetVideoFeedAsync(userId.Value, request, cancellationToken);
            return TypedResults.Ok(response);
        }
        catch (VideoServiceException ex)
        {
            return TypedResults.BadRequest(ex.Message);
        }
    }

    private static async Task<Results<Ok<VideoFeedResponse>, UnauthorizedHttpResult>> GetTrendingVideos(
        ClaimsPrincipal user,
        IVideoService videoService,
        int page = 1,
        int pageSize = 20,
        CancellationToken cancellationToken = default)
    {
        var userId = GetUserId(user);
        if (userId == null)
            return TypedResults.Unauthorized();

        try
        {
            var request = new VideoFeedRequest(page, pageSize, VideoFeedType.Trending);
            var response = await videoService.GetVideoFeedAsync(userId.Value, request, cancellationToken);
            return TypedResults.Ok(response);
        }
        catch (VideoServiceException)
        {
            // Return empty feed on error for trending
            var emptyResponse = new VideoFeedResponse(Array.Empty<VideoDto>(), 0, page, pageSize, false);
            return TypedResults.Ok(emptyResponse);
        }
    }

    private static async Task<Results<Ok<VideoDto>, NotFound, UnauthorizedHttpResult, BadRequest<string>>> GetVideo(
        Guid videoId,
        ClaimsPrincipal user,
        IVideoService videoService,
        CancellationToken cancellationToken = default)
    {
        var userId = GetUserId(user);
        if (userId == null)
            return TypedResults.Unauthorized();

        try
        {
            var video = await videoService.GetVideoAsync(videoId, userId, cancellationToken);
            return TypedResults.Ok(video);
        }
        catch (VideoServiceException ex) when (ex.Message.Contains("not found"))
        {
            return TypedResults.NotFound();
        }
        catch (VideoServiceException ex)
        {
            return TypedResults.BadRequest(ex.Message);
        }
    }

    private static async Task<Results<NoContent, BadRequest<string>, UnauthorizedHttpResult>> RecordVideoInteraction(
        Guid videoId,
        VideoInteractionRequest request,
        ClaimsPrincipal user,
        IVideoService videoService,
        IValidator<VideoInteractionRequest> validator,
        CancellationToken cancellationToken = default)
    {
        var userId = GetUserId(user);
        if (userId == null)
            return TypedResults.Unauthorized();

        var validationResult = await validator.ValidateAsync(request, cancellationToken);
        if (!validationResult.IsValid)
        {
            return TypedResults.BadRequest(string.Join(", ", validationResult.Errors.Select(e => e.ErrorMessage)));
        }

        try
        {
            var success = await videoService.RecordInteractionAsync(userId.Value, videoId, request, cancellationToken);
            return success ? TypedResults.NoContent() : TypedResults.BadRequest("Failed to record interaction");
        }
        catch (VideoServiceException ex)
        {
            return TypedResults.BadRequest(ex.Message);
        }
    }

    private static async Task<Results<Ok<CreatorDto>, NotFound, UnauthorizedHttpResult, BadRequest<string>>> GetCreator(
        Guid creatorId,
        ClaimsPrincipal user,
        IVideoService videoService,
        CancellationToken cancellationToken = default)
    {
        var userId = GetUserId(user);
        if (userId == null)
            return TypedResults.Unauthorized();

        try
        {
            var creator = await videoService.GetCreatorAsync(creatorId, userId, cancellationToken);
            return TypedResults.Ok(creator);
        }
        catch (VideoServiceException ex) when (ex.Message.Contains("not found"))
        {
            return TypedResults.NotFound();
        }
        catch (VideoServiceException ex)
        {
            return TypedResults.BadRequest(ex.Message);
        }
    }

    private static async Task<Results<NoContent, BadRequest<string>, UnauthorizedHttpResult>> FollowCreator(
        Guid creatorId,
        VideoInteractionRequest request,
        ClaimsPrincipal user,
        IVideoService videoService,
        CancellationToken cancellationToken = default)
    {
        var userId = GetUserId(user);
        if (userId == null)
            return TypedResults.Unauthorized();

        try
        {
            await videoService.FollowCreatorAsync(userId.Value, creatorId, cancellationToken);
            return TypedResults.NoContent();
        }
        catch (VideoServiceException ex)
        {
            return TypedResults.BadRequest(ex.Message);
        }
    }

    private static Guid? GetUserId(ClaimsPrincipal user)
    {
        var userIdClaim = user.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        return Guid.TryParse(userIdClaim, out var userId) ? userId : null;
    }
}