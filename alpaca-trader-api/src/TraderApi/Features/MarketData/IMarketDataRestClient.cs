namespace TraderApi.Features.MarketData;

public interface IMarketDataRestClient
{
    Task<AlpacaLatestQuoteResponse?> GetLatestQuoteAsync(string symbol);
    Task<AlpacaLatestTradeResponse?> GetLatestTradeAsync(string symbol);
    Task<AlpacaBarsResponse?> GetBarsAsync(string symbol, string timeframe = "1Day", int limit = 1);
}

// Alpaca REST API response models
public record AlpacaLatestQuoteResponse
{
    public string Symbol { get; init; } = string.Empty;
    public AlpacaQuoteData? Quote { get; init; }
}

public record AlpacaQuoteData
{
    public decimal AskPrice { get; init; }
    public int AskSize { get; init; }
    public decimal BidPrice { get; init; }
    public int BidSize { get; init; }
    public DateTime Timestamp { get; init; }
}

public record AlpacaLatestTradeResponse
{
    public string Symbol { get; init; } = string.Empty;
    public AlpacaTradeData? Trade { get; init; }
}

public record AlpacaTradeData
{
    public decimal Price { get; init; }
    public int Size { get; init; }
    public DateTime Timestamp { get; init; }
}

public record AlpacaBarsResponse
{
    public string Symbol { get; init; } = string.Empty;
    public List<AlpacaBarData> Bars { get; init; } = new();
    public string? NextPageToken { get; init; }
}

public record AlpacaBarData
{
    public DateTime Timestamp { get; init; }
    public decimal Open { get; init; }
    public decimal High { get; init; }
    public decimal Low { get; init; }
    public decimal Close { get; init; }
    public long Volume { get; init; }
    public int TradeCount { get; init; }
    public decimal Vwap { get; init; }
}