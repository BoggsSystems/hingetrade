using System.Net.Http.Headers;
using System.Text.Json;

namespace TraderApi.Features.MarketData;

public class AlpacaMarketDataRestClient : IMarketDataRestClient
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<AlpacaMarketDataRestClient> _logger;
    private readonly IConfiguration _configuration;
    private readonly string _apiKey;
    private readonly string _apiSecret;
    private readonly string _dataUrl;
    private readonly JsonSerializerOptions _jsonOptions;

    public AlpacaMarketDataRestClient(
        HttpClient httpClient,
        ILogger<AlpacaMarketDataRestClient> logger,
        IConfiguration configuration)
    {
        _httpClient = httpClient;
        _logger = logger;
        _configuration = configuration;
        
        _apiKey = configuration["ALPACA_API_KEY_ID"] ?? configuration["Alpaca:ApiKeyId"] ?? 
            throw new InvalidOperationException("ALPACA_API_KEY_ID not configured");
        _apiSecret = configuration["ALPACA_API_SECRET"] ?? configuration["Alpaca:ApiSecret"] ?? 
            throw new InvalidOperationException("ALPACA_API_SECRET not configured");
        
        var alpacaEnv = configuration["ALPACA_ENV"] ?? configuration["Alpaca:Env"] ?? "sandbox";
        var isPaper = alpacaEnv.ToLower() == "sandbox" || alpacaEnv.ToLower() == "paper";
        
        // Use data URL for market data endpoints - sandbox uses data.sandbox.alpaca.markets
        _dataUrl = configuration["Alpaca:DataUrl"] ?? (isPaper 
            ? "https://data.sandbox.alpaca.markets"
            : "https://data.alpaca.markets");
        
        _jsonOptions = new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.SnakeCaseLower,
            PropertyNameCaseInsensitive = true
        };
        
        // Configure HTTP client
        _httpClient.BaseAddress = new Uri(_dataUrl);
        _httpClient.DefaultRequestHeaders.Add("APCA-API-KEY-ID", _apiKey);
        _httpClient.DefaultRequestHeaders.Add("APCA-API-SECRET-KEY", _apiSecret);
        _httpClient.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
        
        _logger.LogInformation("📊 Initialized Alpaca Market Data REST Client with base URL: {BaseUrl}", _dataUrl);
    }

    public async Task<AlpacaLatestQuoteResponse?> GetLatestQuoteAsync(string symbol)
    {
        try
        {
            _logger.LogInformation("📈 Fetching latest quote for {Symbol} from REST API", symbol);
            
            var response = await _httpClient.GetAsync($"/v2/stocks/{symbol}/quotes/latest?feed=iex");
            
            if (!response.IsSuccessStatusCode)
            {
                var error = await response.Content.ReadAsStringAsync();
                _logger.LogWarning("❌ Failed to fetch latest quote for {Symbol}: {StatusCode} - {Error}", 
                    symbol, response.StatusCode, error);
                return null;
            }
            
            var content = await response.Content.ReadAsStringAsync();
            _logger.LogDebug("📊 Raw quote response: {Content}", content);
            
            var result = JsonSerializer.Deserialize<AlpacaLatestQuoteResponse>(content, _jsonOptions);
            
            if (result?.Quote != null)
            {
                _logger.LogInformation("✅ Successfully fetched latest quote for {Symbol}: Bid=${BidPrice}x{BidSize}, Ask=${AskPrice}x{AskSize}", 
                    symbol, result.Quote.BidPrice, result.Quote.BidSize, result.Quote.AskPrice, result.Quote.AskSize);
            }
            
            return result;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "❌ Error fetching latest quote for {Symbol}", symbol);
            return null;
        }
    }

    public async Task<AlpacaLatestTradeResponse?> GetLatestTradeAsync(string symbol)
    {
        try
        {
            _logger.LogInformation("💹 Fetching latest trade for {Symbol} from REST API", symbol);
            
            var response = await _httpClient.GetAsync($"/v2/stocks/{symbol}/trades/latest?feed=iex");
            
            if (!response.IsSuccessStatusCode)
            {
                var error = await response.Content.ReadAsStringAsync();
                _logger.LogWarning("❌ Failed to fetch latest trade for {Symbol}: {StatusCode} - {Error}", 
                    symbol, response.StatusCode, error);
                return null;
            }
            
            var content = await response.Content.ReadAsStringAsync();
            var result = JsonSerializer.Deserialize<AlpacaLatestTradeResponse>(content, _jsonOptions);
            
            if (result?.Trade != null)
            {
                _logger.LogInformation("✅ Successfully fetched latest trade for {Symbol}: Price=${Price}, Size={Size}", 
                    symbol, result.Trade.Price, result.Trade.Size);
            }
            
            return result;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "❌ Error fetching latest trade for {Symbol}", symbol);
            return null;
        }
    }

    public async Task<AlpacaBarsResponse?> GetBarsAsync(string symbol, string timeframe = "1Day", int limit = 1)
    {
        try
        {
            _logger.LogInformation("📊 Fetching bars for {Symbol} from REST API (timeframe: {Timeframe}, limit: {Limit})", 
                symbol, timeframe, limit);
            
            var response = await _httpClient.GetAsync($"/v2/stocks/{symbol}/bars?timeframe={timeframe}&limit={limit}&feed=iex");
            
            if (!response.IsSuccessStatusCode)
            {
                var error = await response.Content.ReadAsStringAsync();
                _logger.LogWarning("❌ Failed to fetch bars for {Symbol}: {StatusCode} - {Error}", 
                    symbol, response.StatusCode, error);
                return null;
            }
            
            var content = await response.Content.ReadAsStringAsync();
            var result = JsonSerializer.Deserialize<AlpacaBarsResponse>(content, _jsonOptions);
            
            if (result?.Bars?.Any() == true)
            {
                var latestBar = result.Bars.Last();
                _logger.LogInformation("✅ Successfully fetched {Count} bar(s) for {Symbol}. Latest: Close=${Close}, Volume={Volume}", 
                    result.Bars.Count, symbol, latestBar.Close, latestBar.Volume);
            }
            
            return result;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "❌ Error fetching bars for {Symbol}", symbol);
            return null;
        }
    }
}