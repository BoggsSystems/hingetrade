using TraderApi.Alpaca;
using TraderApi.Features.Assets;

namespace TraderApi.Features.Orders.Risk;

public interface IRiskService
{
    Task<List<RiskViolation>> ValidateOrderAsync(CreateOrderRequest request, string apiKeyId, string apiSecret);
}

public class RiskService : IRiskService
{
    private readonly List<IRiskRule> _rules;
    private readonly IAlpacaClient _alpacaClient;
    private readonly IAssetValidationService _assetValidationService;
    private readonly ILogger<RiskService> _logger;
    private readonly RiskSettings _riskSettings;

    public RiskService(
        RiskSettings riskSettings,
        IAlpacaClient alpacaClient,
        IAssetValidationService assetValidationService,
        ILogger<RiskService> logger)
    {
        _alpacaClient = alpacaClient;
        _assetValidationService = assetValidationService;
        _logger = logger;
        _riskSettings = riskSettings;

        _rules = new List<IRiskRule>
        {
            new MaxOrderNotionalRule(riskSettings.MaxOrderNotional),
            new MaxShareQuantityRule(riskSettings.MaxShareQuantity),
            new TradingHoursRule(riskSettings.RegularHoursOnly)
        };
        
        // Add dynamic rules based on configuration
        if (riskSettings.AllowedSymbols.Count > 0)
        {
            _rules.Add(new SymbolWhitelistRule(riskSettings.AllowedSymbols));
        }
        if (riskSettings.BlockedSymbols.Count > 0)
        {
            _rules.Add(new SymbolBlocklistRule(riskSettings.BlockedSymbols));
        }
    }

    public async Task<List<RiskViolation>> ValidateOrderAsync(CreateOrderRequest request, string apiKeyId, string apiSecret)
    {
        var violations = new List<RiskViolation>();
        
        // First validate the asset itself
        if (_riskSettings.RequireTradableAsset)
        {
            var asset = await _assetValidationService.GetAssetInfoAsync(request.Symbol);
            if (asset == null)
            {
                violations.Add(new RiskViolation("AssetNotFound", $"Asset {request.Symbol} not found"));
                return violations;
            }
            
            if (!asset.Tradable)
            {
                violations.Add(new RiskViolation("AssetNotTradable", $"Asset {request.Symbol} is not tradable"));
            }
            
            // Check fractional shares
            if (request.Qty % 1 != 0 && !asset.Fractionable)
            {
                violations.Add(new RiskViolation("FractionalNotSupported", $"{request.Symbol} does not support fractional shares"));
            }
            
            // Check if fractionable is required
            if (_riskSettings.RequireFractionable && !asset.Fractionable)
            {
                violations.Add(new RiskViolation("FractionalRequired", $"{request.Symbol} must support fractional shares"));
            }
        }
        
        // Get current price for market orders
        decimal? currentPrice = null;
        if (request.Type == "market")
        {
            try
            {
                var quotes = await _alpacaClient.GetLatestQuotesAsync(apiKeyId, apiSecret, new List<string> { request.Symbol });
                if (quotes.TryGetValue(request.Symbol, out var quote))
                {
                    currentPrice = (quote.AskPrice + quote.BidPrice) / 2;
                    
                    // Check price limits
                    if (currentPrice < _riskSettings.MinPrice)
                    {
                        violations.Add(new RiskViolation("PriceTooLow", $"Price ${currentPrice} is below minimum ${_riskSettings.MinPrice}"));
                    }
                    if (currentPrice > _riskSettings.MaxPrice)
                    {
                        violations.Add(new RiskViolation("PriceTooHigh", $"Price ${currentPrice} is above maximum ${_riskSettings.MaxPrice}"));
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Failed to get current price for {Symbol}", request.Symbol);
            }
        }

        // Run all configured rules
        foreach (var rule in _rules)
        {
            var violation = await rule.ValidateAsync(request, currentPrice);
            if (violation != null)
            {
                violations.Add(violation);
            }
        }

        return violations;
    }
}