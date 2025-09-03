using System.Text.Json;
using System.Text.Json.Serialization;
using System.Globalization;

namespace TraderApi.Features.MarketData;

public class YahooFinanceClient : IYahooFinanceClient
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<YahooFinanceClient> _logger;
    private readonly JsonSerializerOptions _jsonOptions;

    public YahooFinanceClient(HttpClient httpClient, ILogger<YahooFinanceClient> logger)
    {
        _httpClient = httpClient;
        _logger = logger;
        
        _jsonOptions = new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
            PropertyNameCaseInsensitive = true,
            DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull
        };

        // Configure HTTP client
        _httpClient.DefaultRequestHeaders.Add("User-Agent", 
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36");
        
        _logger.LogInformation("🎯 Initialized Yahoo Finance Client");
    }

    public async Task<YahooQuoteResponse?> GetLatestQuoteAsync(string symbol)
    {
        try
        {
            _logger.LogInformation("📊 Fetching latest quote for {Symbol} from Yahoo Finance", symbol);
            
            // Yahoo Finance query API
            var url = $"https://query1.finance.yahoo.com/v8/finance/chart/{symbol}";
            
            var response = await _httpClient.GetAsync(url);
            
            if (!response.IsSuccessStatusCode)
            {
                var error = await response.Content.ReadAsStringAsync();
                _logger.LogWarning("❌ Failed to fetch Yahoo quote for {Symbol}: {StatusCode} - {Error}", 
                    symbol, response.StatusCode, error);
                return null;
            }
            
            var content = await response.Content.ReadAsStringAsync();
            _logger.LogDebug("📊 Raw Yahoo response: {Content}", content.Substring(0, Math.Min(500, content.Length)));
            
            var yahooResponse = JsonSerializer.Deserialize<YahooChartResponse>(content, _jsonOptions);
            
            if (yahooResponse?.Chart?.Result?.FirstOrDefault() is not { } result)
            {
                _logger.LogWarning("❌ No data in Yahoo response for {Symbol}", symbol);
                return null;
            }

            var meta = result.Meta;
            var quote = new YahooQuoteData
            {
                RegularMarketPrice = meta.RegularMarketPrice,
                RegularMarketPreviousClose = meta.PreviousClose,
                RegularMarketOpen = meta.RegularMarketOpen ?? meta.RegularMarketPrice,
                RegularMarketDayHigh = meta.RegularMarketDayHigh ?? meta.RegularMarketPrice,
                RegularMarketDayLow = meta.RegularMarketDayLow ?? meta.RegularMarketPrice,
                RegularMarketVolume = meta.RegularMarketVolume,
                PostMarketPrice = meta.PostMarketPrice,
                PostMarketChange = meta.PostMarketChange,
                PostMarketChangePercent = meta.PostMarketChangePercent,
                PreMarketPrice = meta.PreMarketPrice,
                PreMarketChange = meta.PreMarketChange,
                PreMarketChangePercent = meta.PreMarketChangePercent,
                RegularMarketTime = DateTimeOffset.FromUnixTimeSeconds(meta.RegularMarketTime).DateTime,
                PostMarketTime = meta.PostMarketTime.HasValue ? DateTimeOffset.FromUnixTimeSeconds(meta.PostMarketTime.Value).DateTime : null,
                PreMarketTime = meta.PreMarketTime.HasValue ? DateTimeOffset.FromUnixTimeSeconds(meta.PreMarketTime.Value).DateTime : null,
                MarketState = meta.MarketState ?? "REGULAR"
            };

            var quoteResponse = new YahooQuoteResponse
            {
                Symbol = symbol,
                Quote = quote
            };

            _logger.LogInformation("✅ Successfully fetched Yahoo quote for {Symbol}: Price=${Price}, State={State}", 
                symbol, quote.RegularMarketPrice, quote.MarketState);

            return quoteResponse;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "❌ Error fetching Yahoo quote for {Symbol}", symbol);
            return null;
        }
    }

    public async Task<YahooHistoricalResponse?> GetHistoricalDataAsync(string symbol, DateTime? startDate = null, DateTime? endDate = null)
    {
        try
        {
            var start = startDate ?? DateTime.UtcNow.AddDays(-30);
            var end = endDate ?? DateTime.UtcNow;
            
            var startUnix = ((DateTimeOffset)start).ToUnixTimeSeconds();
            var endUnix = ((DateTimeOffset)end).ToUnixTimeSeconds();
            
            _logger.LogInformation("📈 Fetching historical data for {Symbol} from {StartDate} to {EndDate}", 
                symbol, start.ToString("yyyy-MM-dd"), end.ToString("yyyy-MM-dd"));
            
            var url = $"https://query1.finance.yahoo.com/v8/finance/chart/{symbol}?period1={startUnix}&period2={endUnix}&interval=1d";
            
            var response = await _httpClient.GetAsync(url);
            
            if (!response.IsSuccessStatusCode)
            {
                var error = await response.Content.ReadAsStringAsync();
                _logger.LogWarning("❌ Failed to fetch Yahoo historical data for {Symbol}: {StatusCode} - {Error}", 
                    symbol, response.StatusCode, error);
                return new YahooHistoricalResponse
                {
                    Symbol = symbol,
                    HasError = true,
                    ErrorMessage = $"HTTP {response.StatusCode}: {error}"
                };
            }
            
            var content = await response.Content.ReadAsStringAsync();
            var yahooResponse = JsonSerializer.Deserialize<YahooChartResponse>(content, _jsonOptions);
            
            if (yahooResponse?.Chart?.Result?.FirstOrDefault() is not { } result)
            {
                _logger.LogWarning("❌ No historical data in Yahoo response for {Symbol}", symbol);
                return new YahooHistoricalResponse
                {
                    Symbol = symbol,
                    HasError = true,
                    ErrorMessage = "No data returned from Yahoo Finance"
                };
            }

            var prices = new List<YahooHistoricalData>();
            var timestamps = result.Timestamp ?? new List<long>();
            var indicators = result.Indicators?.Quote?.FirstOrDefault();
            var adjClose = result.Indicators?.AdjClose?.FirstOrDefault()?.AdjClose;

            for (int i = 0; i < timestamps.Count; i++)
            {
                if (indicators == null) continue;

                var open = indicators.Open?.ElementAtOrDefault(i);
                var high = indicators.High?.ElementAtOrDefault(i);
                var low = indicators.Low?.ElementAtOrDefault(i);
                var close = indicators.Close?.ElementAtOrDefault(i);
                var volume = indicators.Volume?.ElementAtOrDefault(i);
                var adj = adjClose?.ElementAtOrDefault(i);

                // Skip if essential data is missing
                if (!close.HasValue) continue;

                prices.Add(new YahooHistoricalData
                {
                    Date = DateTimeOffset.FromUnixTimeSeconds(timestamps[i]).DateTime,
                    Open = open ?? close.Value,
                    High = high ?? close.Value,
                    Low = low ?? close.Value,
                    Close = close.Value,
                    AdjClose = adj ?? close.Value,
                    Volume = volume ?? 0
                });
            }

            var historicalResponse = new YahooHistoricalResponse
            {
                Symbol = symbol,
                Prices = prices
            };

            _logger.LogInformation("✅ Successfully fetched {Count} historical data points for {Symbol}", 
                prices.Count, symbol);

            return historicalResponse;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "❌ Error fetching Yahoo historical data for {Symbol}", symbol);
            return new YahooHistoricalResponse
            {
                Symbol = symbol,
                HasError = true,
                ErrorMessage = ex.Message
            };
        }
    }
}

// Yahoo Finance API response models for deserialization
internal record YahooChartResponse
{
    public YahooChart? Chart { get; init; }
}

internal record YahooChart
{
    public List<YahooResult>? Result { get; init; }
    public YahooError? Error { get; init; }
}

internal record YahooResult
{
    public YahooMeta Meta { get; init; } = new();
    public List<long>? Timestamp { get; init; }
    public YahooIndicators? Indicators { get; init; }
}

internal record YahooMeta
{
    public string Currency { get; init; } = "USD";
    public string Symbol { get; init; } = string.Empty;
    public string ExchangeName { get; init; } = string.Empty;
    public string InstrumentType { get; init; } = string.Empty;
    public long FirstTradeDate { get; init; }
    public long RegularMarketTime { get; init; }
    public int Gmtoffset { get; init; }
    public string Timezone { get; init; } = string.Empty;
    public string ExchangeTimezoneName { get; init; } = string.Empty;
    public decimal RegularMarketPrice { get; init; }
    public decimal ChartPreviousClose { get; init; }
    public decimal PreviousClose { get; init; }
    public int Scale { get; init; }
    public int PriceHint { get; init; }
    public decimal? RegularMarketOpen { get; init; }
    public decimal? RegularMarketDayHigh { get; init; }
    public decimal? RegularMarketDayLow { get; init; }
    public long RegularMarketVolume { get; init; }
    public string? MarketState { get; init; }
    public decimal? PostMarketPrice { get; init; }
    public decimal? PostMarketChange { get; init; }
    public decimal? PostMarketChangePercent { get; init; }
    public long? PostMarketTime { get; init; }
    public decimal? PreMarketPrice { get; init; }
    public decimal? PreMarketChange { get; init; }
    public decimal? PreMarketChangePercent { get; init; }
    public long? PreMarketTime { get; init; }
}

internal record YahooIndicators
{
    public List<YahooQuoteIndicator>? Quote { get; init; }
    public List<YahooAdjClose>? AdjClose { get; init; }
}

internal record YahooQuoteIndicator
{
    public List<decimal?>? Open { get; init; }
    public List<decimal?>? High { get; init; }
    public List<decimal?>? Low { get; init; }
    public List<decimal?>? Close { get; init; }
    public List<long?>? Volume { get; init; }
}

internal record YahooAdjClose
{
    public List<decimal?>? AdjClose { get; init; }
}

internal record YahooError
{
    public string Code { get; init; } = string.Empty;
    public string Description { get; init; } = string.Empty;
}