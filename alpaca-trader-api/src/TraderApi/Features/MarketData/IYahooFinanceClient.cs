namespace TraderApi.Features.MarketData;

public interface IYahooFinanceClient
{
    Task<YahooQuoteResponse?> GetLatestQuoteAsync(string symbol);
    Task<YahooHistoricalResponse?> GetHistoricalDataAsync(string symbol, DateTime? startDate = null, DateTime? endDate = null);
}

// Yahoo Finance response models
public record YahooQuoteResponse
{
    public string Symbol { get; init; } = string.Empty;
    public YahooQuoteData? Quote { get; init; }
}

public record YahooQuoteData
{
    public decimal RegularMarketPrice { get; init; }
    public decimal RegularMarketPreviousClose { get; init; }
    public decimal RegularMarketOpen { get; init; }
    public decimal RegularMarketDayHigh { get; init; }
    public decimal RegularMarketDayLow { get; init; }
    public long RegularMarketVolume { get; init; }
    public decimal? PostMarketPrice { get; init; }
    public decimal? PostMarketChange { get; init; }
    public decimal? PostMarketChangePercent { get; init; }
    public decimal? PreMarketPrice { get; init; }
    public decimal? PreMarketChange { get; init; }
    public decimal? PreMarketChangePercent { get; init; }
    public DateTime RegularMarketTime { get; init; }
    public DateTime? PostMarketTime { get; init; }
    public DateTime? PreMarketTime { get; init; }
    public string MarketState { get; init; } = "REGULAR"; // REGULAR, PRE, POST, CLOSED
}

public record YahooHistoricalResponse
{
    public string Symbol { get; init; } = string.Empty;
    public List<YahooHistoricalData> Prices { get; init; } = new();
    public bool HasError { get; init; }
    public string? ErrorMessage { get; init; }
}

public record YahooHistoricalData
{
    public DateTime Date { get; init; }
    public decimal Open { get; init; }
    public decimal High { get; init; }
    public decimal Low { get; init; }
    public decimal Close { get; init; }
    public decimal AdjClose { get; init; }
    public long Volume { get; init; }
}