namespace TraderApi.Features.Orders.Risk;

public class RiskViolation
{
    public string Rule { get; set; } = default!;
    public string Message { get; set; } = default!;
    
    public RiskViolation() { }
    
    public RiskViolation(string rule, string message)
    {
        Rule = rule;
        Message = message;
    }
}

public interface IRiskRule
{
    Task<RiskViolation?> ValidateAsync(CreateOrderRequest request, decimal? currentPrice = null);
}

public class MaxOrderNotionalRule : IRiskRule
{
    private readonly decimal _maxNotional;

    public MaxOrderNotionalRule(decimal maxNotional)
    {
        _maxNotional = maxNotional;
    }

    public Task<RiskViolation?> ValidateAsync(CreateOrderRequest request, decimal? currentPrice = null)
    {
        decimal price = request.Type == "limit" ? request.LimitPrice!.Value : currentPrice ?? 0;
        
        if (price == 0)
            return Task.FromResult<RiskViolation?>(null); // Skip if we can't determine price
            
        decimal notional = request.Qty * price;
        
        if (notional > _maxNotional)
        {
            return Task.FromResult<RiskViolation?>(new RiskViolation
            {
                Rule = "MaxOrderNotional",
                Message = $"Order notional ${notional:N2} exceeds maximum ${_maxNotional:N2}"
            });
        }

        return Task.FromResult<RiskViolation?>(null);
    }
}

public class MaxShareQuantityRule : IRiskRule
{
    private readonly int _maxShares;

    public MaxShareQuantityRule(int maxShares)
    {
        _maxShares = maxShares;
    }

    public Task<RiskViolation?> ValidateAsync(CreateOrderRequest request, decimal? currentPrice = null)
    {
        if (request.Qty > _maxShares)
        {
            return Task.FromResult<RiskViolation?>(new RiskViolation
            {
                Rule = "MaxShareQuantity",
                Message = $"Order quantity {request.Qty} exceeds maximum {_maxShares} shares"
            });
        }

        return Task.FromResult<RiskViolation?>(null);
    }
}

public class SymbolWhitelistRule : IRiskRule
{
    private readonly HashSet<string> _allowedSymbols;

    public SymbolWhitelistRule(List<string> allowedSymbols)
    {
        _allowedSymbols = new HashSet<string>(allowedSymbols, StringComparer.OrdinalIgnoreCase);
    }

    public Task<RiskViolation?> ValidateAsync(CreateOrderRequest request, decimal? currentPrice = null)
    {
        if (!_allowedSymbols.Contains(request.Symbol))
        {
            return Task.FromResult<RiskViolation?>(new RiskViolation
            {
                Rule = "SymbolWhitelist",
                Message = $"Symbol {request.Symbol} is not in the allowed list"
            });
        }

        return Task.FromResult<RiskViolation?>(null);
    }
}

public class SymbolBlocklistRule : IRiskRule
{
    private readonly HashSet<string> _blockedSymbols;

    public SymbolBlocklistRule(List<string> blockedSymbols)
    {
        _blockedSymbols = new HashSet<string>(blockedSymbols, StringComparer.OrdinalIgnoreCase);
    }

    public Task<RiskViolation?> ValidateAsync(CreateOrderRequest request, decimal? currentPrice = null)
    {
        if (_blockedSymbols.Contains(request.Symbol))
        {
            return Task.FromResult<RiskViolation?>(new RiskViolation
            {
                Rule = "SymbolBlocklist",
                Message = $"Symbol {request.Symbol} is blocked from trading"
            });
        }

        return Task.FromResult<RiskViolation?>(null);
    }
}

public class TradingHoursRule : IRiskRule
{
    private readonly bool _regularHoursOnly;

    public TradingHoursRule(bool regularHoursOnly)
    {
        _regularHoursOnly = regularHoursOnly;
    }

    public Task<RiskViolation?> ValidateAsync(CreateOrderRequest request, decimal? currentPrice = null)
    {
        if (!_regularHoursOnly)
            return Task.FromResult<RiskViolation?>(null);

        var now = DateTime.UtcNow;
        var easternTime = TimeZoneInfo.ConvertTimeFromUtc(now, TimeZoneInfo.FindSystemTimeZoneById("America/New_York"));
        var currentTime = easternTime.TimeOfDay;
        
        // If extended hours is requested, validate extended hours times
        if (request.ExtendedHours == true)
        {
            var preMarketOpen = new TimeSpan(4, 0, 0);
            var afterMarketClose = new TimeSpan(20, 0, 0);
            
            if (currentTime < preMarketOpen || currentTime > afterMarketClose)
            {
                return Task.FromResult<RiskViolation?>(new RiskViolation
                {
                    Rule = "ExtendedTradingHours",
                    Message = "Extended hours orders are only allowed between 4:00 AM - 8:00 PM ET"
                });
            }
        }
        else
        {
            // Regular hours check
            var marketOpen = new TimeSpan(9, 30, 0);
            var marketClose = new TimeSpan(16, 0, 0);
            
            if (currentTime < marketOpen || currentTime > marketClose)
            {
                return Task.FromResult<RiskViolation?>(new RiskViolation
                {
                    Rule = "TradingHours",
                    Message = "Orders are only allowed during regular market hours (9:30 AM - 4:00 PM ET)"
                });
            }
        }

        // Check if it's a weekend
        if (easternTime.DayOfWeek == DayOfWeek.Saturday || easternTime.DayOfWeek == DayOfWeek.Sunday)
        {
            return Task.FromResult<RiskViolation?>(new RiskViolation
            {
                Rule = "TradingHours",
                Message = "Orders are not allowed on weekends"
            });
        }

        return Task.FromResult<RiskViolation?>(null);
    }
}