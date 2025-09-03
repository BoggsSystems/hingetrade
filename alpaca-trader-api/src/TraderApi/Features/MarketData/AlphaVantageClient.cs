using System.Text.Json;
using System.Text.Json.Serialization;

namespace TraderApi.Features.MarketData;

public class AlphaVantageClient
{
    private readonly HttpClient _httpClient;
    private readonly IConfiguration _configuration;
    private readonly ILogger<AlphaVantageClient> _logger;
    private readonly SemaphoreSlim _rateLimiter;
    private readonly Queue<DateTime> _requestTimestamps;
    private readonly int _maxRequestsPerMinute;

    public AlphaVantageClient(
        HttpClient httpClient,
        IConfiguration configuration,
        ILogger<AlphaVantageClient> logger)
    {
        _httpClient = httpClient;
        _configuration = configuration;
        _logger = logger;
        _maxRequestsPerMinute = configuration.GetValue<int>("AlphaVantage:RateLimitPerMinute", 5);
        _rateLimiter = new SemaphoreSlim(1, 1);
        _requestTimestamps = new Queue<DateTime>();
    }

    public async Task<SymbolSearchResponse?> SearchSymbolsAsync(string keywords, CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("[AlphaVantage] ===== SearchSymbolsAsync called with keywords: '{Keywords}' =====", keywords);
        
        if (string.IsNullOrWhiteSpace(keywords))
        {
            _logger.LogInformation("[AlphaVantage] Empty keywords, returning empty response");
            return new SymbolSearchResponse { BestMatches = new List<SymbolMatch>() };
        }

        _logger.LogInformation("[AlphaVantage] Enforcing rate limit...");
        await EnforceRateLimitAsync();

        try
        {
            // Try multiple configuration sources for the API key
            var configApiKey = _configuration["AlphaVantage:ApiKey"];
            var envApiKey1 = _configuration["ALPHA_VANTAGE_API_KEY"];
            var envApiKey2 = Environment.GetEnvironmentVariable("ALPHA_VANTAGE_API_KEY");
            
            _logger.LogInformation("[AlphaVantage] API key sources - Config: {Config}, Env1: {Env1}, Env2: {Env2}", 
                configApiKey != null ? $"SET({configApiKey.Length})" : "NULL",
                envApiKey1 != null ? $"SET({envApiKey1.Length})" : "NULL", 
                envApiKey2 != null ? $"SET({envApiKey2.Length})" : "NULL");
                
            var apiKey = !string.IsNullOrEmpty(configApiKey) ? configApiKey : 
                         !string.IsNullOrEmpty(envApiKey1) ? envApiKey1 : envApiKey2;
            
            _logger.LogInformation("[AlphaVantage] Final API key: {ApiKey}", apiKey != null ? $"SET({apiKey.Length})" : "NULL");
                
            if (string.IsNullOrEmpty(apiKey))
            {
                _logger.LogWarning("[AlphaVantage] Alpha Vantage API key not configured. Set AlphaVantage:ApiKey in appsettings or ALPHA_VANTAGE_API_KEY in environment");
                return null;
            }

            _logger.LogInformation("[AlphaVantage] Using API key: {ApiKey}", apiKey.Substring(0, Math.Min(8, apiKey.Length)) + "...");

            var baseUrl = _configuration["AlphaVantage:BaseUrl"] ?? "https://www.alphavantage.co/query";
            var url = $"{baseUrl}?function=SYMBOL_SEARCH&keywords={Uri.EscapeDataString(keywords)}&apikey={apiKey}";
            
            _logger.LogInformation("[AlphaVantage] Making request to: {Url}", url.Replace(apiKey, "***"));

            var response = await _httpClient.GetAsync(url, cancellationToken);
            
            _logger.LogInformation("[AlphaVantage] Response status: {StatusCode}", response.StatusCode);
            
            if (!response.IsSuccessStatusCode)
            {
                _logger.LogWarning("[AlphaVantage] Alpha Vantage API returned status {StatusCode}", response.StatusCode);
                return null;
            }

            var json = await response.Content.ReadAsStringAsync(cancellationToken);
            _logger.LogInformation("[AlphaVantage] Response JSON: {Json}", json.Length > 500 ? json.Substring(0, 500) + "..." : json);
            
            // Check for API limit messages
            if (json.Contains("Thank you for using Alpha Vantage") || 
                json.Contains("standard API rate limit") ||
                json.Contains("daily rate limits"))
            {
                _logger.LogWarning("[AlphaVantage] Alpha Vantage API rate limit exceeded, returning mock data for development");
                
                // Return mock data for common symbols to continue development
                return GetMockResponse(keywords);
            }

            var searchResponse = JsonSerializer.Deserialize<SymbolSearchResponse>(json, new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
                // Remove PropertyNamingPolicy since we're using explicit JsonPropertyName attributes
            });

            _logger.LogInformation("[AlphaVantage] Deserialized response: {MatchCount} matches", 
                searchResponse?.BestMatches?.Count ?? 0);

            return searchResponse;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "[AlphaVantage] Error searching symbols with Alpha Vantage");
            return null;
        }
    }

    private async Task EnforceRateLimitAsync()
    {
        await _rateLimiter.WaitAsync();
        try
        {
            var now = DateTime.UtcNow;
            var oneMinuteAgo = now.AddMinutes(-1);

            // Remove timestamps older than 1 minute
            while (_requestTimestamps.Count > 0 && _requestTimestamps.Peek() < oneMinuteAgo)
            {
                _requestTimestamps.Dequeue();
            }

            // If we've hit the rate limit, wait until the oldest request is 1 minute old
            if (_requestTimestamps.Count >= _maxRequestsPerMinute)
            {
                var oldestRequest = _requestTimestamps.Peek();
                var waitTime = oldestRequest.AddMinutes(1) - now;
                
                if (waitTime > TimeSpan.Zero)
                {
                    _logger.LogDebug("Rate limit reached, waiting {WaitTime}ms", waitTime.TotalMilliseconds);
                    await Task.Delay(waitTime);
                }
                
                _requestTimestamps.Dequeue();
            }

            _requestTimestamps.Enqueue(now);
        }
        finally
        {
            _rateLimiter.Release();
        }
    }

    private SymbolSearchResponse GetMockResponse(string keywords)
        {
            var mockData = new Dictionary<string, List<SymbolMatch>>
            {
                ["AAPL"] = new List<SymbolMatch>
                {
                    new SymbolMatch { Symbol = "AAPL", Name = "Apple Inc", Type = "Equity", Region = "United States", Currency = "USD" }
                },
                ["MSFT"] = new List<SymbolMatch>
                {
                    new SymbolMatch { Symbol = "MSFT", Name = "Microsoft Corporation", Type = "Equity", Region = "United States", Currency = "USD" }
                },
                ["TSLA"] = new List<SymbolMatch>
                {
                    new SymbolMatch { Symbol = "TSLA", Name = "Tesla Inc", Type = "Equity", Region = "United States", Currency = "USD" }
                },
                ["GOOGL"] = new List<SymbolMatch>
                {
                    new SymbolMatch { Symbol = "GOOGL", Name = "Alphabet Inc Class A", Type = "Equity", Region = "United States", Currency = "USD" }
                },
                ["AMZN"] = new List<SymbolMatch>
                {
                    new SymbolMatch { Symbol = "AMZN", Name = "Amazon.com Inc", Type = "Equity", Region = "United States", Currency = "USD" }
                },
                ["MICROSOFT"] = new List<SymbolMatch>
                {
                    new SymbolMatch { Symbol = "MSFT", Name = "Microsoft Corporation", Type = "Equity", Region = "United States", Currency = "USD" }
                },
                ["APPLE"] = new List<SymbolMatch>
                {
                    new SymbolMatch { Symbol = "AAPL", Name = "Apple Inc", Type = "Equity", Region = "United States", Currency = "USD" }
                },
                ["TESLA"] = new List<SymbolMatch>
                {
                    new SymbolMatch { Symbol = "TSLA", Name = "Tesla Inc", Type = "Equity", Region = "United States", Currency = "USD" }
                }
            };

            var upperKeywords = keywords.ToUpper();
            var matches = new List<SymbolMatch>();

            // Find exact matches first
            if (mockData.ContainsKey(upperKeywords))
            {
                matches.AddRange(mockData[upperKeywords]);
            }
            else
            {
                // Find partial matches
                foreach (var kvp in mockData)
                {
                    if (kvp.Key.Contains(upperKeywords) || kvp.Value.Any(m => m.Name.ToUpper().Contains(upperKeywords)))
                    {
                        matches.AddRange(kvp.Value);
                    }
                }
            }

            _logger.LogInformation("[AlphaVantage] Returning {Count} mock matches for '{Keywords}'", matches.Count, keywords);

            return new SymbolSearchResponse { BestMatches = matches };
        }
    }

public class SymbolSearchResponse
{
    [JsonPropertyName("bestMatches")]
    public List<SymbolMatch> BestMatches { get; set; } = new();
}

public class SymbolMatch
{
    [JsonPropertyName("1. symbol")]
    public string Symbol { get; set; } = "";

    [JsonPropertyName("2. name")]
    public string Name { get; set; } = "";

    [JsonPropertyName("3. type")]
    public string Type { get; set; } = "";

    [JsonPropertyName("4. region")]
    public string Region { get; set; } = "";

    [JsonPropertyName("8. currency")]
    public string Currency { get; set; } = "";

    [JsonPropertyName("9. matchScore")]
    public string MatchScore { get; set; } = "";
}