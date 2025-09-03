using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using TraderApi.Features.Auth.Data;
using TraderApi.Features.Auth.Models;
using TraderApi.Alpaca;
using TraderApi.Alpaca.Models;
using TraderApi.Features.Funding.Models;

namespace TraderApi.Features.Funding;

public static class FundingEndpoints
{
    public static void MapFundingEndpoints(this WebApplication app)
    {
        var funding = app.MapGroup("/api/funding")
            .RequireAuthorization()
            .WithTags("Funding");
            
        funding.MapGet("/bank-accounts", GetBankAccounts);
        funding.MapGet("/transfers", GetTransfers);
        funding.MapPost("/transfers/ach", InitiateAchTransfer);
        funding.MapGet("/transfers/{transferId}", GetTransferStatus);
        
        // Plaid endpoints
        funding.MapPost("/plaid/link-token", CreatePlaidLinkToken);
        funding.MapPost("/plaid/exchange-token", ExchangePlaidToken);
        funding.MapPost("/plaid/create-ach-relationship", CreateAchRelationshipWithPlaid);
    }
    
    private static async Task<IResult> GetBankAccounts(
        ClaimsPrincipal user,
        AuthDbContext authDb,
        IAlpacaClient alpacaClient,
        ILogger<Program> logger)
    {
        var sub = user.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        Console.WriteLine($"[FUNDING-DEBUG] GetBankAccounts called with sub: {sub}");
        
        var userId = Guid.Parse(sub ?? throw new UnauthorizedAccessException());
        Console.WriteLine($"[FUNDING-DEBUG] Looking for auth user with ID: {userId}");
        
        var authUser = await authDb.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(u => u.Id == userId);
            
        if (authUser == null)
        {
            Console.WriteLine($"[FUNDING-DEBUG] No auth user found for ID: {userId}");
            return TypedResults.NotFound("User not found");
        }
        
        Console.WriteLine($"[FUNDING-DEBUG] Found auth user: {authUser.Email}, AlpacaAccountId: {authUser.AlpacaAccountId ?? "NULL"}");
        
        if (string.IsNullOrEmpty(authUser.AlpacaAccountId))
        {
            Console.WriteLine($"[FUNDING-DEBUG] AlpacaAccountId is null/empty for user {authUser.Email}");
            return TypedResults.BadRequest("Alpaca account not linked");
        }
            
        try
        {
            var apiKeyId = Environment.GetEnvironmentVariable("ALPACA_API_KEY_ID");
            var apiSecret = Environment.GetEnvironmentVariable("ALPACA_API_SECRET");
            
            if (string.IsNullOrEmpty(apiKeyId) || string.IsNullOrEmpty(apiSecret))
            {
                logger.LogError("Alpaca API credentials not configured");
                return TypedResults.Problem("API configuration error");
            }
            
            // Get bank relationships from Alpaca
            var relationships = await alpacaClient.GetBankRelationshipsAsync(
                apiKeyId, 
                apiSecret, 
                authUser.AlpacaAccountId);
                
            return TypedResults.Ok(relationships);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Error fetching bank accounts for user {UserId}", userId);
            return TypedResults.Problem("Failed to fetch bank accounts");
        }
    }
    
    private static async Task<IResult> InitiateAchTransfer(
        [FromBody] AchTransferRequest request,
        ClaimsPrincipal user,
        AuthDbContext authDb,
        IAlpacaClient alpacaClient,
        ILogger<Program> logger)
    {
        var userId = Guid.Parse(user.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? throw new UnauthorizedAccessException());
        
        var authUser = await authDb.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(u => u.Id == userId);
            
        if (authUser == null || string.IsNullOrEmpty(authUser.AlpacaAccountId))
            return TypedResults.NotFound("User or Alpaca account not found");
            
        // Validate request
        if (request.Amount <= 0)
            return TypedResults.BadRequest("Amount must be greater than 0");
            
        if (request.Direction != "INCOMING" && request.Direction != "OUTGOING")
            return TypedResults.BadRequest("Direction must be INCOMING or OUTGOING");
            
        try
        {
            var apiKeyId = Environment.GetEnvironmentVariable("ALPACA_API_KEY_ID");
            var apiSecret = Environment.GetEnvironmentVariable("ALPACA_API_SECRET");
            
            if (string.IsNullOrEmpty(apiKeyId) || string.IsNullOrEmpty(apiSecret))
            {
                logger.LogError("Alpaca API credentials not configured");
                return TypedResults.Problem("API configuration error");
            }
            
            // Create ACH transfer via Alpaca
            var alpacaRequest = new AlpacaAchTransferRequest
            {
                Amount = request.Amount.ToString(),
                Direction = request.Direction,
                RelationshipId = request.RelationshipId ?? "default" // Use default bank if not specified
            };
            
            var transfer = await alpacaClient.CreateAchTransferAsync(
                apiKeyId,
                apiSecret,
                authUser.AlpacaAccountId,
                alpacaRequest);
                
            logger.LogInformation(
                "Initiated {Direction} ACH transfer of ${Amount} for user {UserId}", 
                request.Direction, 
                request.Amount, 
                userId);
                
            return TypedResults.Ok(new
            {
                transferId = transfer.Id,
                status = transfer.Status,
                amount = request.Amount,
                direction = request.Direction,
                initiatedAt = DateTime.UtcNow,
                message = request.Direction == "INCOMING" 
                    ? "Deposit initiated. Funds will be available in 3-5 business days."
                    : "Withdrawal initiated. Funds will be transferred in 3-5 business days."
            });
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Error initiating ACH transfer for user {UserId}", userId);
            return TypedResults.Problem("Failed to initiate transfer");
        }
    }
    
    private static async Task<IResult> GetTransfers(
        ClaimsPrincipal user,
        AuthDbContext authDb,
        IAlpacaClient alpacaClient,
        ILogger<Program> logger)
    {
        var userId = Guid.Parse(user.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? throw new UnauthorizedAccessException());
        
        var authUser = await authDb.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(u => u.Id == userId);
            
        if (authUser == null || string.IsNullOrEmpty(authUser.AlpacaAccountId))
            return TypedResults.NotFound("User or Alpaca account not found");
            
        try
        {
            var apiKeyId = Environment.GetEnvironmentVariable("ALPACA_API_KEY_ID");
            var apiSecret = Environment.GetEnvironmentVariable("ALPACA_API_SECRET");
            
            if (string.IsNullOrEmpty(apiKeyId) || string.IsNullOrEmpty(apiSecret))
            {
                logger.LogError("Alpaca API credentials not configured");
                return TypedResults.Problem("API configuration error");
            }
            
            // Get transfers from Alpaca
            var transfers = await alpacaClient.GetTransfersAsync(
                apiKeyId,
                apiSecret,
                authUser.AlpacaAccountId);
                
            return TypedResults.Ok(transfers);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Error fetching transfers for user {UserId}", userId);
            return TypedResults.Problem("Failed to fetch transfers");
        }
    }
    
    private static async Task<IResult> GetTransferStatus(
        string transferId,
        ClaimsPrincipal user,
        AuthDbContext authDb,
        IAlpacaClient alpacaClient,
        ILogger<Program> logger)
    {
        var userId = Guid.Parse(user.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? throw new UnauthorizedAccessException());
        
        var authUser = await authDb.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(u => u.Id == userId);
            
        if (authUser == null || string.IsNullOrEmpty(authUser.AlpacaAccountId))
            return TypedResults.NotFound("User or Alpaca account not found");
            
        try
        {
            var apiKeyId = Environment.GetEnvironmentVariable("ALPACA_API_KEY_ID");
            var apiSecret = Environment.GetEnvironmentVariable("ALPACA_API_SECRET");
            
            if (string.IsNullOrEmpty(apiKeyId) || string.IsNullOrEmpty(apiSecret))
            {
                logger.LogError("Alpaca API credentials not configured");
                return TypedResults.Problem("API configuration error");
            }
            
            // Get specific transfer from Alpaca
            var transfer = await alpacaClient.GetTransferAsync(
                apiKeyId,
                apiSecret,
                authUser.AlpacaAccountId,
                transferId);
                
            if (transfer == null)
                return TypedResults.NotFound("Transfer not found");
                
            return TypedResults.Ok(transfer);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Error fetching transfer {TransferId} for user {UserId}", transferId, userId);
            return TypedResults.Problem("Failed to fetch transfer status");
        }
    }
    
    private static async Task<IResult> CreatePlaidLinkToken(
        [FromBody] PlaidLinkRequest request,
        IPlaidService plaidService,
        ILogger<Program> logger)
    {
        try
        {
            var response = await plaidService.CreateLinkTokenAsync(request.UserId, request.UserEmail);
            return TypedResults.Ok(response);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Failed to create Plaid link token");
            return TypedResults.Problem("Failed to create Plaid link token");
        }
    }
    
    private static async Task<IResult> ExchangePlaidToken(
        [FromBody] PlaidTokenExchangeRequest request,
        IPlaidService plaidService,
        ILogger<Program> logger)
    {
        try
        {
            var response = await plaidService.ExchangePublicTokenAsync(request.PublicToken);
            return TypedResults.Ok(response);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Failed to exchange Plaid public token");
            return TypedResults.Problem("Failed to exchange Plaid public token");
        }
    }
    
    private static async Task<IResult> CreateAchRelationshipWithPlaid(
        [FromBody] PlaidProcessorTokenRequest request,
        ClaimsPrincipal user,
        AuthDbContext authDb,
        IAlpacaClient alpacaClient,
        IPlaidService plaidService,
        ILogger<Program> logger)
    {
        var userId = Guid.Parse(user.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? throw new UnauthorizedAccessException());
        
        var authUser = await authDb.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(u => u.Id == userId);
            
        if (authUser == null || string.IsNullOrEmpty(authUser.AlpacaAccountId))
            return TypedResults.NotFound("User or Alpaca account not found");
            
        try
        {
            var apiKeyId = Environment.GetEnvironmentVariable("ALPACA_API_KEY_ID");
            var apiSecret = Environment.GetEnvironmentVariable("ALPACA_API_SECRET");
            
            if (string.IsNullOrEmpty(apiKeyId) || string.IsNullOrEmpty(apiSecret))
            {
                logger.LogError("Alpaca API credentials not configured");
                return TypedResults.Problem("API configuration error");
            }
            
            // Step 1: Exchange public token for access token
            var exchangeResponse = await plaidService.ExchangePublicTokenAsync(request.PublicToken);
            
            // Step 2: Create processor token for Alpaca
            var processorResponse = await plaidService.CreateProcessorTokenAsync(
                exchangeResponse.AccessToken, 
                request.AccountId);
            
            // Step 3: Create ACH relationship in Alpaca using processor token
            var relationshipRequest = new AlpacaAchRelationshipRequest
            {
                AccountOwnerName = authUser.Username ?? authUser.Email,
                BankAccountType = "CHECKING", // Default to checking, could be passed from frontend
                ProcessorToken = processorResponse.ProcessorToken,
                AchProcessor = "plaid"
            };
            
            var relationship = await alpacaClient.CreateAchRelationshipAsync(
                apiKeyId,
                apiSecret,
                authUser.AlpacaAccountId,
                relationshipRequest);
                
            logger.LogInformation(
                "Created ACH relationship for user {UserId} via Plaid", 
                userId);
                
            return TypedResults.Ok(new
            {
                relationshipId = relationship.Id,
                status = relationship.Status,
                message = "Bank account successfully linked"
            });
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Failed to create ACH relationship with Plaid for user {UserId}", userId);
            return TypedResults.Problem("Failed to link bank account");
        }
    }
}

public record AchTransferRequest(
    decimal Amount,
    string Direction, // INCOMING or OUTGOING
    string? RelationshipId // Bank relationship ID (optional)
);