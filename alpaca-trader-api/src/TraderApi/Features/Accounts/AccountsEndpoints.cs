using System.Security.Claims;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.EntityFrameworkCore;
using TraderApi.Features.Auth.Data;
using TraderApi.Features.Orders;

namespace TraderApi.Features.Accounts;

public static class AccountsEndpoints
{
    public static void MapAccountsEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api")
            .RequireAuthorization()
            .WithTags("Accounts");

        group.MapGet("/me", GetUserProfile)
            .WithName("GetUserProfile")
            .WithSummary("Get current user profile")
            .Produces<UserProfileDto>();

        group.MapGet("/account", GetAccount)
            .WithName("GetAccount")
            .WithSummary("Get Alpaca account details")
            .WithDescription("Proxy to Alpaca /v2/account endpoint")
            .Produces<AccountDto>()
            .Produces(400);

        group.MapPost("/account/link", LinkAccount)
            .WithName("LinkAccount")
            .WithSummary("Link Alpaca API credentials")
            .WithDescription("Store user's Alpaca API keys (encrypted)")
            .Produces<LinkAccountResponse>()
            .Produces(400);
    }

    private static async Task<Ok<UserProfileDto>> GetUserProfile(
        IAccountsService accountsService,
        ClaimsPrincipal user)
    {
        var authSub = user.FindFirst(ClaimTypes.NameIdentifier)?.Value 
            ?? throw new UnauthorizedAccessException("User ID not found in token");
            
        var profile = await accountsService.GetUserProfileAsync(authSub);
        return TypedResults.Ok(profile);
    }

    private static async Task<Results<Ok<AccountDto>, BadRequest<ErrorResponse>>> GetAccount(
        IAccountsService accountsService,
        AuthDbContext authDb,
        ClaimsPrincipal user)
    {
        try
        {
            Console.WriteLine($"GetAccount called for user: {user.Identity?.Name}");
            var userId = await GetUserIdAsync(authDb, user);
            Console.WriteLine($"Found userId: {userId}");
            var account = await accountsService.GetAccountAsync(userId);
            return TypedResults.Ok(account);
        }
        catch (InvalidOperationException ex)
        {
            Console.WriteLine($"Error getting account: {ex.Message}");
            return TypedResults.BadRequest(new ErrorResponse("AccountError", ex.Message));
        }
    }

    private static async Task<Results<Ok<LinkAccountResponse>, BadRequest<ErrorResponse>>> LinkAccount(
        IAccountsService accountsService,
        AuthDbContext authDb,
        ClaimsPrincipal user,
        LinkAccountRequest request)
    {
        try
        {
            var userId = await GetUserIdAsync(authDb, user);
            var response = await accountsService.LinkAccountAsync(userId, request);
            return TypedResults.Ok(response);
        }
        catch (InvalidOperationException ex)
        {
            return TypedResults.BadRequest(new ErrorResponse("LinkError", ex.Message));
        }
    }

    private static async Task<Guid> GetUserIdAsync(AuthDbContext authDb, ClaimsPrincipal user)
    {
        var sub = user.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(sub))
            throw new UnauthorizedAccessException("User ID not found in token");
            
        // Debug: log all claims
        Console.WriteLine($"Sub claim: {sub}");
        foreach (var claim in user.Claims)
        {
            Console.WriteLine($"Claim: {claim.Type} = {claim.Value}");
        }
            
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
    
    private static Guid GetUserId(ClaimsPrincipal user)
    {
        var sub = user.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(sub))
            throw new UnauthorizedAccessException("User ID not found in token");
            
        if (Guid.TryParse(sub, out var userId))
            return userId;
            
        throw new InvalidOperationException("Invalid user ID format");
    }
}