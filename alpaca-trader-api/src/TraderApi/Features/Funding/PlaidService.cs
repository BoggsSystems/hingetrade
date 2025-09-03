using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using TraderApi.Features.Funding.Models;

namespace TraderApi.Features.Funding;

public interface IPlaidService
{
    Task<PlaidLinkTokenResponse> CreateLinkTokenAsync(string userId, string userEmail);
    Task<PlaidTokenExchangeResponse> ExchangePublicTokenAsync(string publicToken);
    Task<PlaidProcessorTokenResponse> CreateProcessorTokenAsync(string accessToken, string accountId);
}

public class PlaidService : IPlaidService
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<PlaidService> _logger;
    private readonly string _clientId;
    private readonly string _secret;
    private readonly string _environment;

    public PlaidService(HttpClient httpClient, ILogger<PlaidService> logger, IConfiguration configuration)
    {
        _httpClient = httpClient;
        _logger = logger;
        
        var plaidSection = configuration.GetSection("Plaid");
        _clientId = plaidSection["ClientId"] ?? throw new InvalidOperationException("Plaid:ClientId not configured");
        _secret = plaidSection["Secret"] ?? throw new InvalidOperationException("Plaid:Secret not configured");
        _environment = plaidSection["Environment"] ?? "sandbox";
        
        _logger.LogInformation($"Plaid configured with ClientId: {_clientId?.Substring(0, 10)}..., Environment: {_environment}");
        _logger.LogInformation($"Plaid secret (first 10 chars): {_secret?.Substring(0, Math.Min(10, _secret?.Length ?? 0))}...");
        
        _httpClient.BaseAddress = new Uri($"https://{_environment}.plaid.com");
        _httpClient.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
    }

    public async Task<PlaidLinkTokenResponse> CreateLinkTokenAsync(string userId, string userEmail)
    {
        var request = new
        {
            client_id = _clientId,
            secret = _secret,
            user = new { client_user_id = userId, email_address = userEmail },
            client_name = "HingeTrade",
            products = new[] { "auth" },
            country_codes = new[] { "US" },
            language = "en",
            webhook = $"https://api.hingetrade.com/webhooks/plaid", // Optional webhook
            account_filters = new
            {
                depository = new
                {
                    account_subtypes = new[] { "checking", "savings" }
                }
            }
        };

        var json = JsonSerializer.Serialize(request);
        var content = new StringContent(json, Encoding.UTF8, "application/json");

        var response = await _httpClient.PostAsync("/link/token/create", content);
        
        if (!response.IsSuccessStatusCode)
        {
            var errorContent = await response.Content.ReadAsStringAsync();
            _logger.LogError($"Plaid API error: {response.StatusCode} - {errorContent}");
        }
        
        response.EnsureSuccessStatusCode();

        var responseJson = await response.Content.ReadAsStringAsync();
        var result = JsonSerializer.Deserialize<PlaidLinkTokenResponse>(responseJson);
        
        if (result == null)
            throw new InvalidOperationException("Failed to create Plaid link token");
            
        _logger.LogInformation("Created Plaid link token for user {UserId}", userId);
        return result;
    }

    public async Task<PlaidTokenExchangeResponse> ExchangePublicTokenAsync(string publicToken)
    {
        var request = new
        {
            client_id = _clientId,
            secret = _secret,
            public_token = publicToken
        };

        var json = JsonSerializer.Serialize(request);
        var content = new StringContent(json, Encoding.UTF8, "application/json");

        var response = await _httpClient.PostAsync("/item/public_token/exchange", content);
        response.EnsureSuccessStatusCode();

        var responseJson = await response.Content.ReadAsStringAsync();
        var result = JsonSerializer.Deserialize<PlaidTokenExchangeResponse>(responseJson);
        
        if (result == null)
            throw new InvalidOperationException("Failed to exchange public token");
            
        _logger.LogInformation("Exchanged Plaid public token successfully");
        return result;
    }

    public async Task<PlaidProcessorTokenResponse> CreateProcessorTokenAsync(string accessToken, string accountId)
    {
        var request = new
        {
            client_id = _clientId,
            secret = _secret,
            access_token = accessToken,
            account_id = accountId,
            processor = "alpaca"
        };

        var json = JsonSerializer.Serialize(request);
        var content = new StringContent(json, Encoding.UTF8, "application/json");

        var response = await _httpClient.PostAsync("/processor/token/create", content);
        
        if (!response.IsSuccessStatusCode)
        {
            var errorContent = await response.Content.ReadAsStringAsync();
            _logger.LogError($"Plaid processor token error: {response.StatusCode} - {errorContent}");
        }
        
        response.EnsureSuccessStatusCode();

        var responseJson = await response.Content.ReadAsStringAsync();
        var result = JsonSerializer.Deserialize<PlaidProcessorTokenResponse>(responseJson);
        
        if (result == null)
            throw new InvalidOperationException("Failed to create processor token");
            
        _logger.LogInformation("Created Alpaca processor token for account {AccountId}", accountId);
        return result;
    }
}