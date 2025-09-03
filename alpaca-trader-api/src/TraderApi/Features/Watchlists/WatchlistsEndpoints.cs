using System.Security.Claims;
using Microsoft.AspNetCore.Http.HttpResults;
using TraderApi.Features.Orders;

namespace TraderApi.Features.Watchlists;

public static class WatchlistsEndpoints
{
    public static void MapWatchlistsEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/watchlists")
            .RequireAuthorization()
            .WithTags("Watchlists");

        group.MapGet("/", GetWatchlists)
            .WithName("GetWatchlists")
            .WithSummary("Get user's watchlists")
            .Produces<List<WatchlistDto>>();

        group.MapPost("/", CreateWatchlist)
            .WithName("CreateWatchlist")
            .WithSummary("Create a new watchlist")
            .Produces<WatchlistDto>(201)
            .Produces(400);

        group.MapPost("/{id}/symbols", AddSymbol)
            .WithName("AddSymbolToWatchlist")
            .WithSummary("Add symbol to watchlist")
            .Produces(204)
            .Produces(400)
            .Produces(404);

        group.MapDelete("/{id}/symbols/{symbol}", RemoveSymbol)
            .WithName("RemoveSymbolFromWatchlist")
            .WithSummary("Remove symbol from watchlist")
            .Produces(204)
            .Produces(404);
    }

    private static async Task<Ok<List<WatchlistDto>>> GetWatchlists(
        IWatchlistsService watchlistsService,
        ClaimsPrincipal user)
    {
        var userId = GetUserId(user);
        var watchlists = await watchlistsService.GetWatchlistsAsync(userId);
        return TypedResults.Ok(watchlists);
    }

    private static async Task<Results<Created<WatchlistDto>, BadRequest<ErrorResponse>>> CreateWatchlist(
        IWatchlistsService watchlistsService,
        ClaimsPrincipal user,
        CreateWatchlistRequest request)
    {
        try
        {
            var userId = GetUserId(user);
            var watchlist = await watchlistsService.CreateWatchlistAsync(userId, request);
            return TypedResults.Created($"/api/watchlists/{watchlist.Id}", watchlist);
        }
        catch (InvalidOperationException ex)
        {
            return TypedResults.BadRequest(new ErrorResponse("WatchlistError", ex.Message));
        }
    }

    private static async Task<Results<NoContent, BadRequest<ErrorResponse>, NotFound>> AddSymbol(
        IWatchlistsService watchlistsService,
        ClaimsPrincipal user,
        Guid id,
        AddSymbolRequest request)
    {
        try
        {
            var userId = GetUserId(user);
            var success = await watchlistsService.AddSymbolAsync(userId, id, request);
            return success ? TypedResults.NoContent() : TypedResults.NotFound();
        }
        catch (InvalidOperationException ex)
        {
            return TypedResults.BadRequest(new ErrorResponse("SymbolError", ex.Message));
        }
    }

    private static async Task<Results<NoContent, NotFound>> RemoveSymbol(
        IWatchlistsService watchlistsService,
        ClaimsPrincipal user,
        Guid id,
        string symbol)
    {
        var userId = GetUserId(user);
        var success = await watchlistsService.RemoveSymbolAsync(userId, id, symbol);
        return success ? TypedResults.NoContent() : TypedResults.NotFound();
    }

    private static Guid GetUserId(ClaimsPrincipal user)
    {
        var sub = user.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(sub))
            throw new UnauthorizedAccessException("User ID not found in token");
            
        return Guid.Parse("00000000-0000-0000-0000-" + sub.GetHashCode().ToString("X").PadLeft(12, '0'));
    }
}