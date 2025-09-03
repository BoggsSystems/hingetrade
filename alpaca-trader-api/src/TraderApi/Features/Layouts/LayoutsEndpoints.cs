using System.Security.Claims;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TraderApi.Features.Auth.Data;

namespace TraderApi.Features.Layouts;

public static class LayoutsEndpoints
{
    public static void MapLayoutsEndpoints(this IEndpointRouteBuilder routes)
    {
        var group = routes.MapGroup("/api/layouts")
            .WithTags("Layouts")
            .RequireAuthorization()
            .WithOpenApi();

        group.MapGet("/", GetLayouts)
            .WithName("GetLayouts")
            .WithSummary("Get all layouts for the current user");

        group.MapGet("/{layoutId}", GetLayout)
            .WithName("GetLayout")
            .WithSummary("Get a specific layout");

        group.MapPost("/", CreateLayout)
            .WithName("CreateLayout")
            .WithSummary("Create a new layout");

        group.MapPut("/{layoutId}", UpdateLayout)
            .WithName("UpdateLayout")
            .WithSummary("Update an existing layout");

        group.MapDelete("/{layoutId}", DeleteLayout)
            .WithName("DeleteLayout")
            .WithSummary("Delete a layout");

        group.MapPost("/{layoutId}/set-default", SetDefaultLayout)
            .WithName("SetDefaultLayout")
            .WithSummary("Set a layout as the default");
    }

    private static async Task<IResult> GetLayouts(
        ILayoutsService layoutsService,
        AuthDbContext authDb,
        ClaimsPrincipal user)
    {
        var userId = await GetUserIdAsync(authDb, user);
        var layouts = await layoutsService.GetLayoutsAsync(userId);
        return Results.Ok(layouts);
    }

    private static async Task<IResult> GetLayout(
        Guid layoutId,
        ILayoutsService layoutsService,
        AuthDbContext authDb,
        ClaimsPrincipal user)
    {
        try
        {
            var userId = await GetUserIdAsync(authDb, user);
            var layout = await layoutsService.GetLayoutAsync(userId, layoutId);
            return Results.Ok(layout);
        }
        catch (InvalidOperationException ex)
        {
            return Results.NotFound(new { error = ex.Message });
        }
    }

    private static async Task<IResult> CreateLayout(
        CreateLayoutRequest request,
        ILayoutsService layoutsService,
        AuthDbContext authDb,
        ClaimsPrincipal user)
    {
        try
        {
            var userId = await GetUserIdAsync(authDb, user);
            var layout = await layoutsService.CreateLayoutAsync(userId, request);
            return Results.Created($"/api/layouts/{layout.Id}", layout);
        }
        catch (InvalidOperationException ex)
        {
            return Results.BadRequest(new { error = ex.Message });
        }
    }

    private static async Task<IResult> UpdateLayout(
        Guid layoutId,
        UpdateLayoutRequest request,
        ILayoutsService layoutsService,
        AuthDbContext authDb,
        ClaimsPrincipal user,
        ILogger<Program> logger)
    {
        try
        {
            logger.LogInformation("UpdateLayout endpoint called for layout {LayoutId}", layoutId);
            var userId = await GetUserIdAsync(authDb, user);
            logger.LogInformation("User ID resolved: {UserId}", userId);
            
            var layout = await layoutsService.UpdateLayoutAsync(userId, layoutId, request);
            logger.LogInformation("Layout update completed successfully for layout {LayoutId}", layoutId);
            return Results.Ok(layout);
        }
        catch (InvalidOperationException ex)
        {
            logger.LogWarning(ex, "InvalidOperationException in UpdateLayout for layout {LayoutId}: {Message}", layoutId, ex.Message);
            return Results.BadRequest(new { error = ex.Message });
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Unexpected error in UpdateLayout for layout {LayoutId}. Type: {ExceptionType}", layoutId, ex.GetType().Name);
            return Results.Problem(
                detail: "An error occurred while updating the layout",
                statusCode: 500,
                title: "Internal Server Error");
        }
    }

    private static async Task<IResult> DeleteLayout(
        Guid layoutId,
        ILayoutsService layoutsService,
        AuthDbContext authDb,
        ClaimsPrincipal user)
    {
        try
        {
            var userId = await GetUserIdAsync(authDb, user);
            var deleted = await layoutsService.DeleteLayoutAsync(userId, layoutId);
            if (!deleted) return Results.NotFound();
            return Results.NoContent();
        }
        catch (InvalidOperationException ex)
        {
            return Results.BadRequest(new { error = ex.Message });
        }
    }

    private static async Task<IResult> SetDefaultLayout(
        Guid layoutId,
        ILayoutsService layoutsService,
        AuthDbContext authDb,
        ClaimsPrincipal user)
    {
        try
        {
            var userId = await GetUserIdAsync(authDb, user);
            var layout = await layoutsService.SetDefaultLayoutAsync(userId, layoutId);
            return Results.Ok(layout);
        }
        catch (InvalidOperationException ex)
        {
            return Results.BadRequest(new { error = ex.Message });
        }
    }

    private static async Task<Guid> GetUserIdAsync(AuthDbContext authDb, ClaimsPrincipal user)
    {
        var sub = user.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(sub))
            throw new UnauthorizedAccessException("User ID not found in token");
            
        if (Guid.TryParse(sub, out var userId))
            return userId;
            
        // For non-GUID subs, look up the user by email
        var email = user.FindFirst(ClaimTypes.Email)?.Value;
        var authUser = await authDb.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(u => u.Email == email);
            
        if (authUser == null)
            throw new InvalidOperationException("User not found");
            
        return authUser.Id;
    }
}