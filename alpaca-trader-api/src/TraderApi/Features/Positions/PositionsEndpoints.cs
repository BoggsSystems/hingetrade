using System.Security.Claims;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.EntityFrameworkCore;
using TraderApi.Features.Auth.Data;
using TraderApi.Features.Orders;

namespace TraderApi.Features.Positions;

public static class PositionsEndpoints
{
    public static void MapPositionsEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/positions")
            .RequireAuthorization()
            .WithTags("Positions");

        group.MapGet("/", GetPositions)
            .WithName("GetPositions")
            .WithSummary("Get current positions")
            .WithDescription("Retrieve all open positions from Alpaca")
            .Produces<List<PositionDto>>()
            .Produces(400);
    }

    private static async Task<Results<Ok<List<PositionDto>>, BadRequest<ErrorResponse>>> GetPositions(
        IPositionsService positionsService,
        AuthDbContext authDb,
        ClaimsPrincipal user)
    {
        try
        {
            var userId = await GetUserIdAsync(authDb, user);
            var positions = await positionsService.GetPositionsAsync(userId);
            return TypedResults.Ok(positions);
        }
        catch (InvalidOperationException ex)
        {
            return TypedResults.BadRequest(new ErrorResponse("PositionsError", ex.Message));
        }
    }

    private static async Task<Guid> GetUserIdAsync(AuthDbContext authDb, ClaimsPrincipal user)
    {
        var sub = user.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(sub))
            throw new UnauthorizedAccessException("User ID not found in token");
            
        if (Guid.TryParse(sub, out var userId))
            return userId;
            
        // For non-GUID subs, look up the user
        var email = user.FindFirst(ClaimTypes.Email)?.Value;
        var authUser = await authDb.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(u => u.Email == email);
            
        if (authUser == null)
            throw new InvalidOperationException("User not found");
            
        return authUser.Id;
    }
}