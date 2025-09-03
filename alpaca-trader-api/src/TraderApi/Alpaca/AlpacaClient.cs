using System.Net.Http.Headers;
using System.Net;
using System.Text;
using System.Text.Json;
using Polly;
using Polly.Extensions.Http;
using TraderApi.Alpaca.Models;
using TraderApi.Features.Funding.Models;

namespace TraderApi.Alpaca;

public interface IAlpacaClient
{
    Task<AlpacaAccount> GetAccountAsync(string apiKeyId, string apiSecret, string? brokerAccountId = null);
    Task<List<AlpacaPosition>> GetPositionsAsync(string apiKeyId, string apiSecret, string? brokerAccountId = null);
    Task<List<AlpacaOrder>> GetOrdersAsync(string apiKeyId, string apiSecret, string? status = null, int? limit = null, string? brokerAccountId = null);
    Task<AlpacaOrder> CreateOrderAsync(string apiKeyId, string apiSecret, AlpacaOrderRequest request, string? brokerAccountId = null);
    Task<bool> CancelOrderAsync(string apiKeyId, string apiSecret, string orderId, string? brokerAccountId = null);
    Task<Dictionary<string, AlpacaQuote>> GetLatestQuotesAsync(string apiKeyId, string apiSecret, List<string> symbols);
    Task<List<BrokerAccount>> GetBrokerAccountsAsync(string apiKeyId, string apiSecret);
    Task<BrokerAccount> GetBrokerAccountAsync(string apiKeyId, string apiSecret, string accountId);
    Task<BrokerAccount> CreateBrokerAccountAsync(string apiKeyId, string apiSecret, BrokerAccountRequest request);
    Task<List<AlpacaAsset>> GetAssetsAsync(string? status = null, string? assetClass = null);
    Task<AlpacaAsset?> GetAssetAsync(string symbol);
    Task<List<BankRelationship>> GetBankRelationshipsAsync(string apiKeyId, string apiSecret, string accountId);
    Task<BankRelationship> CreateAchRelationshipAsync(string apiKeyId, string apiSecret, string accountId, AlpacaAchRelationshipRequest request);
    Task<AchTransfer> CreateAchTransferAsync(string apiKeyId, string apiSecret, string accountId, AlpacaAchTransferRequest request);
    Task<List<Transfer>> GetTransfersAsync(string apiKeyId, string apiSecret, string accountId);
    Task<Transfer?> GetTransferAsync(string apiKeyId, string apiSecret, string accountId, string transferId);
}

public class AlpacaClient : IAlpacaClient
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<AlpacaClient> _logger;
    private readonly AlpacaSettings _settings;
    private readonly IAsyncPolicy<HttpResponseMessage> _retryPolicy;

    public AlpacaClient(HttpClient httpClient, ILogger<AlpacaClient> logger, AlpacaSettings settings)
    {
        _httpClient = httpClient;
        _logger = logger;
        _settings = settings;
        
        _logger.LogInformation("Initializing AlpacaClient with BaseUrl: {BaseUrl}", _settings.BaseUrl);
        _httpClient.BaseAddress = new Uri(_settings.BaseUrl);
        _httpClient.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));

        _retryPolicy = HttpPolicyExtensions
            .HandleTransientHttpError()
            .WaitAndRetryAsync(
                3,
                retryAttempt => TimeSpan.FromSeconds(Math.Pow(2, retryAttempt)),
                onRetry: (outcome, timespan, retryCount, context) =>
                {
                    _logger.LogWarning("Delaying for {delay}ms, then making retry {retry}.", timespan.TotalMilliseconds, retryCount);
                });
    }

    private void SetAuthHeaders(string apiKeyId, string apiSecret)
    {
        // Remove existing auth headers
        _httpClient.DefaultRequestHeaders.Remove("Authorization");
        _httpClient.DefaultRequestHeaders.Remove("APCA-API-KEY-ID");
        _httpClient.DefaultRequestHeaders.Remove("APCA-API-SECRET-KEY");
        
        // Check if we're using Broker API based on multiple factors
        var isBrokerApi = IsBrokerApi();
        
        _logger.LogDebug("Using {ApiType} authentication for {BaseUrl}", 
            isBrokerApi ? "Broker API" : "Trading API", 
            _httpClient.BaseAddress);
        
        if (isBrokerApi)
        {
            // Broker API uses Basic Authentication
            var authToken = Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes($"{apiKeyId}:{apiSecret}"));
            _httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Basic", authToken);
        }
        else
        {
            // Trading API uses custom headers
            _httpClient.DefaultRequestHeaders.Add("APCA-API-KEY-ID", apiKeyId);
            _httpClient.DefaultRequestHeaders.Add("APCA-API-SECRET-KEY", apiSecret);
        }
    }

    public async Task<AlpacaAccount> GetAccountAsync(string apiKeyId, string apiSecret, string? brokerAccountId = null)
    {
        SetAuthHeaders(apiKeyId, apiSecret);
        
        string endpoint;
        if (IsBrokerApi() && !string.IsNullOrEmpty(brokerAccountId))
        {
            endpoint = $"/v1/trading/accounts/{brokerAccountId}/account";
        }
        else
        {
            endpoint = "/v2/account";
        }
        
        var response = await _retryPolicy.ExecuteAsync(async () => 
            await _httpClient.GetAsync(endpoint));
        
        response.EnsureSuccessStatusCode();
        
        var json = await response.Content.ReadAsStringAsync();
        _logger.LogDebug("Account response: {Json}", json);
        try
        {
            // Log converter count
            _logger.LogDebug("Using {ConverterCount} converters", AlpacaJsonOptions.Default.Converters.Count);
            foreach (var converter in AlpacaJsonOptions.Default.Converters)
            {
                _logger.LogDebug("Converter: {ConverterType}", converter.GetType().Name);
            }
            
            return JsonSerializer.Deserialize<AlpacaAccount>(json, AlpacaJsonOptions.Default)!;
        }
        catch (JsonException ex)
        {
            _logger.LogError(ex, "Failed to deserialize account response. JSON: {Json}", json);
            throw;
        }
    }

    public async Task<List<AlpacaPosition>> GetPositionsAsync(string apiKeyId, string apiSecret, string? brokerAccountId = null)
    {
        SetAuthHeaders(apiKeyId, apiSecret);
        
        string endpoint;
        if (IsBrokerApi() && !string.IsNullOrEmpty(brokerAccountId))
        {
            endpoint = $"/v1/trading/accounts/{brokerAccountId}/positions";
        }
        else
        {
            endpoint = "/v2/positions";
        }
        
        var response = await _retryPolicy.ExecuteAsync(async () => 
            await _httpClient.GetAsync(endpoint));
        
        response.EnsureSuccessStatusCode();
        
        var json = await response.Content.ReadAsStringAsync();
        return JsonSerializer.Deserialize<List<AlpacaPosition>>(json, AlpacaJsonOptions.Default)!;
    }

    public async Task<List<AlpacaOrder>> GetOrdersAsync(string apiKeyId, string apiSecret, string? status = null, int? limit = null, string? brokerAccountId = null)
    {
        SetAuthHeaders(apiKeyId, apiSecret);
        
        var query = new List<string>();
        if (!string.IsNullOrEmpty(status))
            query.Add($"status={status}");
        if (limit.HasValue)
            query.Add($"limit={limit}");
        
        var queryString = query.Count > 0 ? "?" + string.Join("&", query) : "";
        
        string endpoint;
        if (IsBrokerApi() && !string.IsNullOrEmpty(brokerAccountId))
        {
            endpoint = $"/v1/trading/accounts/{brokerAccountId}/orders{queryString}";
        }
        else
        {
            endpoint = $"/v2/orders{queryString}";
        }
        
        var response = await _retryPolicy.ExecuteAsync(async () => 
            await _httpClient.GetAsync(endpoint));
        
        response.EnsureSuccessStatusCode();
        
        var json = await response.Content.ReadAsStringAsync();
        return JsonSerializer.Deserialize<List<AlpacaOrder>>(json, AlpacaJsonOptions.Default)!;
    }

    public async Task<AlpacaOrder> CreateOrderAsync(string apiKeyId, string apiSecret, AlpacaOrderRequest request, string? brokerAccountId = null)
    {
        SetAuthHeaders(apiKeyId, apiSecret);
        
        var json = JsonSerializer.Serialize(request, AlpacaJsonOptions.Default);
        var content = new StringContent(json, Encoding.UTF8, "application/json");
        
        string endpoint;
        if (IsBrokerApi() && !string.IsNullOrEmpty(brokerAccountId))
        {
            endpoint = $"/v1/trading/accounts/{brokerAccountId}/orders";
        }
        else
        {
            endpoint = "/v2/orders";
        }
        
        var response = await _retryPolicy.ExecuteAsync(async () => 
            await _httpClient.PostAsync(endpoint, content));
        
        response.EnsureSuccessStatusCode();
        
        var responseJson = await response.Content.ReadAsStringAsync();
        return JsonSerializer.Deserialize<AlpacaOrder>(responseJson, AlpacaJsonOptions.Default)!;
    }

    public async Task<bool> CancelOrderAsync(string apiKeyId, string apiSecret, string orderId, string? brokerAccountId = null)
    {
        SetAuthHeaders(apiKeyId, apiSecret);
        
        string endpoint;
        if (IsBrokerApi() && !string.IsNullOrEmpty(brokerAccountId))
        {
            endpoint = $"/v1/trading/accounts/{brokerAccountId}/orders/{orderId}";
        }
        else
        {
            endpoint = $"/v2/orders/{orderId}";
        }
        
        var response = await _retryPolicy.ExecuteAsync(async () => 
            await _httpClient.DeleteAsync(endpoint));
        
        return response.IsSuccessStatusCode;
    }

    public async Task<Dictionary<string, AlpacaQuote>> GetLatestQuotesAsync(string apiKeyId, string apiSecret, List<string> symbols)
    {
        SetAuthHeaders(apiKeyId, apiSecret);
        
        var symbolsParam = string.Join(",", symbols);
        var response = await _retryPolicy.ExecuteAsync(async () => 
            await _httpClient.GetAsync($"/v2/stocks/quotes/latest?symbols={symbolsParam}"));
        
        response.EnsureSuccessStatusCode();
        
        var json = await response.Content.ReadAsStringAsync();
        var result = JsonSerializer.Deserialize<Dictionary<string, object>>(json, AlpacaJsonOptions.Default)!;
        
        if (result.TryGetValue("quotes", out var quotesObj))
        {
            var quotesJson = quotesObj.ToString();
            return JsonSerializer.Deserialize<Dictionary<string, AlpacaQuote>>(quotesJson!, AlpacaJsonOptions.Default)!;
        }
        
        return new Dictionary<string, AlpacaQuote>();
    }

    public async Task<List<BrokerAccount>> GetBrokerAccountsAsync(string apiKeyId, string apiSecret)
    {
        SetAuthHeaders(apiKeyId, apiSecret);
        
        if (!IsBrokerApi())
        {
            throw new InvalidOperationException("This method is only available for Broker API accounts");
        }
        
        var response = await _retryPolicy.ExecuteAsync(async () => 
            await _httpClient.GetAsync("/v1/accounts"));
        
        response.EnsureSuccessStatusCode();
        
        var json = await response.Content.ReadAsStringAsync();
        return JsonSerializer.Deserialize<List<BrokerAccount>>(json, AlpacaJsonOptions.Default)!;
    }

    private bool IsBrokerApi()
    {
        // Check if it's broker API by URL or if we're using a mock/test server with broker endpoints
        var host = _httpClient.BaseAddress?.Host ?? "";
        return host.Contains("broker-api") || 
               (host == "localhost" && _settings.BaseUrl.Contains("localhost"));
    }

    public async Task<List<AlpacaAsset>> GetAssetsAsync(string? status = null, string? assetClass = null)
    {
        var query = new List<string>();
        if (!string.IsNullOrEmpty(status))
            query.Add($"status={status}");
        if (!string.IsNullOrEmpty(assetClass))
            query.Add($"asset_class={assetClass}");
            
        var queryString = query.Count > 0 ? "?" + string.Join("&", query) : "";
        var endpoint = $"/v2/assets{queryString}";
        
        // Assets endpoint doesn't require authentication
        var response = await _retryPolicy.ExecuteAsync(async () => 
            await _httpClient.GetAsync(endpoint));
        
        response.EnsureSuccessStatusCode();
        
        var json = await response.Content.ReadAsStringAsync();
        return JsonSerializer.Deserialize<List<AlpacaAsset>>(json, AlpacaJsonOptions.Default)!;
    }

    public async Task<AlpacaAsset?> GetAssetAsync(string symbol)
    {
        var endpoint = $"/v2/assets/{symbol}";
        
        // Asset endpoint doesn't require authentication
        var response = await _retryPolicy.ExecuteAsync(async () => 
            await _httpClient.GetAsync(endpoint));
        
        if (response.StatusCode == System.Net.HttpStatusCode.NotFound)
            return null;
            
        response.EnsureSuccessStatusCode();
        
        var json = await response.Content.ReadAsStringAsync();
        return JsonSerializer.Deserialize<AlpacaAsset>(json, AlpacaJsonOptions.Default);
    }
    
    public async Task<BrokerAccount> GetBrokerAccountAsync(string apiKeyId, string apiSecret, string accountId)
    {
        SetAuthHeaders(apiKeyId, apiSecret);
        
        if (!IsBrokerApi())
        {
            throw new InvalidOperationException("This method is only available for Broker API accounts");
        }
        
        var response = await _retryPolicy.ExecuteAsync(async () => 
            await _httpClient.GetAsync($"/v1/accounts/{accountId}"));
        
        response.EnsureSuccessStatusCode();
        
        var responseJson = await response.Content.ReadAsStringAsync();
        return JsonSerializer.Deserialize<BrokerAccount>(responseJson, AlpacaJsonOptions.Default)!;
    }

    public async Task<BrokerAccount> CreateBrokerAccountAsync(string apiKeyId, string apiSecret, BrokerAccountRequest request)
    {
        SetAuthHeaders(apiKeyId, apiSecret);
        
        if (!IsBrokerApi())
        {
            throw new InvalidOperationException("This method is only available for Broker API accounts");
        }
        
        var json = JsonSerializer.Serialize(request, AlpacaJsonOptions.Default);
        var content = new StringContent(json, Encoding.UTF8, "application/json");
        
        var response = await _retryPolicy.ExecuteAsync(async () => 
            await _httpClient.PostAsync("/v1/accounts", content));
        
        response.EnsureSuccessStatusCode();
        
        var responseJson = await response.Content.ReadAsStringAsync();
        return JsonSerializer.Deserialize<BrokerAccount>(responseJson, AlpacaJsonOptions.Default)!;
    }
    
    public async Task<List<BankRelationship>> GetBankRelationshipsAsync(string apiKeyId, string apiSecret, string accountId)
    {
        SetAuthHeaders(apiKeyId, apiSecret);
        
        if (!IsBrokerApi())
        {
            throw new InvalidOperationException("This method is only available for Broker API accounts");
        }
        
        var response = await _retryPolicy.ExecuteAsync(async () => 
            await _httpClient.GetAsync($"/v1/accounts/{accountId}/ach_relationships"));
        
        response.EnsureSuccessStatusCode();
        
        var responseJson = await response.Content.ReadAsStringAsync();
        return JsonSerializer.Deserialize<List<BankRelationship>>(responseJson, AlpacaJsonOptions.Default) ?? new List<BankRelationship>();
    }
    
    public async Task<BankRelationship> CreateAchRelationshipAsync(string apiKeyId, string apiSecret, string accountId, AlpacaAchRelationshipRequest request)
    {
        SetAuthHeaders(apiKeyId, apiSecret);
        
        if (!IsBrokerApi())
        {
            throw new InvalidOperationException("This method is only available for Broker API accounts");
        }
        
        var json = JsonSerializer.Serialize(request, AlpacaJsonOptions.Default);
        var content = new StringContent(json, Encoding.UTF8, "application/json");
        
        var response = await _retryPolicy.ExecuteAsync(async () => 
            await _httpClient.PostAsync($"/v1/accounts/{accountId}/ach_relationships", content));
        
        response.EnsureSuccessStatusCode();
        
        var responseJson = await response.Content.ReadAsStringAsync();
        return JsonSerializer.Deserialize<BankRelationship>(responseJson, AlpacaJsonOptions.Default)!;
    }

    public async Task<AchTransfer> CreateAchTransferAsync(string apiKeyId, string apiSecret, string accountId, AlpacaAchTransferRequest request)
    {
        SetAuthHeaders(apiKeyId, apiSecret);
        
        if (!IsBrokerApi())
        {
            throw new InvalidOperationException("This method is only available for Broker API accounts");
        }
        
        var json = JsonSerializer.Serialize(request, AlpacaJsonOptions.Default);
        var content = new StringContent(json, Encoding.UTF8, "application/json");
        
        var response = await _retryPolicy.ExecuteAsync(async () => 
            await _httpClient.PostAsync($"/v1/accounts/{accountId}/transfers", content));
        
        response.EnsureSuccessStatusCode();
        
        var responseJson = await response.Content.ReadAsStringAsync();
        return JsonSerializer.Deserialize<AchTransfer>(responseJson, AlpacaJsonOptions.Default)!;
    }
    
    public async Task<List<Transfer>> GetTransfersAsync(string apiKeyId, string apiSecret, string accountId)
    {
        SetAuthHeaders(apiKeyId, apiSecret);
        
        if (!IsBrokerApi())
        {
            throw new InvalidOperationException("This method is only available for Broker API accounts");
        }
        
        var response = await _retryPolicy.ExecuteAsync(async () => 
            await _httpClient.GetAsync($"/v1/accounts/{accountId}/transfers"));
        
        response.EnsureSuccessStatusCode();
        
        var responseJson = await response.Content.ReadAsStringAsync();
        return JsonSerializer.Deserialize<List<Transfer>>(responseJson, AlpacaJsonOptions.Default) ?? new List<Transfer>();
    }
    
    public async Task<Transfer?> GetTransferAsync(string apiKeyId, string apiSecret, string accountId, string transferId)
    {
        SetAuthHeaders(apiKeyId, apiSecret);
        
        if (!IsBrokerApi())
        {
            throw new InvalidOperationException("This method is only available for Broker API accounts");
        }
        
        var response = await _retryPolicy.ExecuteAsync(async () => 
            await _httpClient.GetAsync($"/v1/accounts/{accountId}/transfers/{transferId}"));
        
        if (!response.IsSuccessStatusCode)
        {
            if (response.StatusCode == HttpStatusCode.NotFound)
                return null;
            response.EnsureSuccessStatusCode();
        }
        
        var responseJson = await response.Content.ReadAsStringAsync();
        return JsonSerializer.Deserialize<Transfer>(responseJson, AlpacaJsonOptions.Default);
    }
}