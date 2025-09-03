using Microsoft.EntityFrameworkCore;
using TraderApi.Alpaca;
using TraderApi.Data;
using TraderApi.Security;
using TraderApi.Features.Auth.Data;

namespace TraderApi.Features.Positions;

public interface IPositionsService
{
    Task<List<PositionDto>> GetPositionsAsync(Guid userId);
}

public class PositionsService : IPositionsService
{
    private readonly AuthDbContext _authDb;
    private readonly IAlpacaClient _alpacaClient;
    private readonly ILogger<PositionsService> _logger;

    public PositionsService(
        AuthDbContext authDb,
        IAlpacaClient alpacaClient,
        ILogger<PositionsService> logger)
    {
        _authDb = authDb;
        _alpacaClient = alpacaClient;
        _logger = logger;
    }

    public async Task<List<PositionDto>> GetPositionsAsync(Guid userId)
    {
        try
        {
            // Get user from auth database
            var authUser = await _authDb.Users
                .AsNoTracking()
                .FirstOrDefaultAsync(u => u.Id == userId);
                
            if (authUser == null || string.IsNullOrEmpty(authUser.AlpacaAccountId))
                throw new InvalidOperationException("Alpaca account not linked");
            
            // Use environment variables for API credentials
            var apiKeyId = Environment.GetEnvironmentVariable("ALPACA_API_KEY_ID");
            var apiSecret = Environment.GetEnvironmentVariable("ALPACA_API_SECRET");
            
            if (string.IsNullOrEmpty(apiKeyId) || string.IsNullOrEmpty(apiSecret))
            {
                _logger.LogError("Alpaca API credentials not configured");
                throw new InvalidOperationException("API configuration error");
            }

            var positions = await _alpacaClient.GetPositionsAsync(apiKeyId, apiSecret, authUser.AlpacaAccountId);

            return positions.Select(p => new PositionDto(
                p.AssetId,
                p.Symbol,
                p.Exchange,
                p.AssetClass,
                p.Qty,
                p.AvgEntryPrice,
                p.Side,
                p.MarketValue,
                p.CostBasis,
                p.UnrealizedPl,
                p.UnrealizedPlpc,
                p.CurrentPrice
            )).ToList();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching positions for user {UserId}", userId);
            throw;
        }
    }
}

public record PositionDto(
    string AssetId,
    string Symbol,
    string Exchange,
    string AssetClass,
    decimal Qty,
    decimal AvgEntryPrice,
    string Side,
    decimal MarketValue,
    decimal CostBasis,
    decimal UnrealizedPl,
    decimal UnrealizedPlpc,
    decimal CurrentPrice
);