using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;
using Microsoft.EntityFrameworkCore;
using TraderApi.Features.Auth.Data;
using TraderApi.Features.Positions;

namespace TraderApi.Features.Portfolio;

public static class PortfolioEndpoints
{
    public static void MapPortfolioEndpoints(this IEndpointRouteBuilder endpoints)
    {
        var group = endpoints.MapGroup("/api/portfolio")
            .WithTags("Portfolio")
            .RequireAuthorization();

        group.MapGet("", GetPortfolio)
            .WithName("GetPortfolio")
            .WithSummary("Get portfolio overview")
            .WithDescription("Returns portfolio overview including account value, positions, and performance metrics");
    }

    private static async Task<IResult> GetPortfolio(
        IPositionsService positionsService,
        AuthDbContext authDb,
        ClaimsPrincipal user)
    {
        try
        {
            var userId = await GetUserIdAsync(authDb, user);
            var positions = await positionsService.GetPositionsAsync(userId);
            
            // Calculate basic portfolio metrics
            var totalValue = positions.Sum(p => p.MarketValue);
            var totalGainLoss = positions.Sum(p => p.UnrealizedPl);
            var totalCostBasis = totalValue - totalGainLoss;
            var totalGainLossPercent = totalCostBasis > 0 ? (double)(totalGainLoss / totalCostBasis) * 100 : 0;

            var portfolio = new
            {
                TotalValue = totalValue,
                DayGainLoss = totalGainLoss,
                DayGainLossPercent = totalGainLossPercent,
                PositionsCount = positions.Count,
                Positions = positions.Select(p => new
                {
                    Symbol = p.Symbol,
                    Quantity = p.Qty,
                    MarketValue = p.MarketValue,
                    CostBasis = p.CostBasis,
                    UnrealizedPnl = p.UnrealizedPl,
                    UnrealizedPnlPercent = p.CostBasis != 0 ? (double)(p.UnrealizedPl / p.CostBasis) * 100 : 0,
                    CurrentPrice = p.CurrentPrice
                }).ToList()
            };

            return Results.Ok(portfolio);
        }
        catch (Exception ex)
        {
            // Log the full exception for debugging
            Console.WriteLine($"Portfolio error: {ex}");
            return Results.Problem($"Error retrieving portfolio: {ex.Message}");
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