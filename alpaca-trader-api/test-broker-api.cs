using System;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text.Json;
using System.Threading.Tasks;

class TestBrokerApi
{
    static async Task Main(string[] args)
    {
        var apiKeyId = "CKB4051UELTQZSUS78S8";
        var apiSecret = "ZdjZPMzxPcAf7aWngyC1UtHJfHdRjvssxIvCJTlA";
        var baseUrl = "https://broker-api.sandbox.alpaca.markets";

        using var client = new HttpClient();
        client.BaseAddress = new Uri(baseUrl);
        client.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
        
        // Use Basic Auth for Broker API
        var authToken = Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes($"{apiKeyId}:{apiSecret}"));
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Basic", authToken);

        try
        {
            Console.WriteLine("Testing Alpaca Broker API connection...\n");
            
            // 1. List all accounts
            Console.WriteLine("1. Listing all accounts:");
            var accountsResponse = await client.GetAsync("/v1/accounts");
            if (accountsResponse.IsSuccessStatusCode)
            {
                var accountsJson = await accountsResponse.Content.ReadAsStringAsync();
                var accounts = JsonDocument.Parse(accountsJson);
                
                Console.WriteLine($"Found {accounts.RootElement.GetArrayLength()} accounts:");
                
                string? firstAccountId = null;
                foreach (var account in accounts.RootElement.EnumerateArray())
                {
                    var id = account.GetProperty("id").GetString();
                    var status = account.GetProperty("status").GetString();
                    var createdAt = account.GetProperty("created_at").GetString();
                    
                    if (firstAccountId == null) firstAccountId = id;
                    
                    Console.WriteLine($"  - Account ID: {id}");
                    Console.WriteLine($"    Status: {status}");
                    Console.WriteLine($"    Created: {createdAt}");
                    Console.WriteLine();
                }
                
                // 2. Get details of first account
                if (!string.IsNullOrEmpty(firstAccountId))
                {
                    Console.WriteLine($"\n2. Getting details for account {firstAccountId}:");
                    var accountDetailResponse = await client.GetAsync($"/v1/accounts/{firstAccountId}");
                    if (accountDetailResponse.IsSuccessStatusCode)
                    {
                        var detailJson = await accountDetailResponse.Content.ReadAsStringAsync();
                        var detail = JsonDocument.Parse(detailJson);
                        Console.WriteLine(JsonSerializer.Serialize(detail, new JsonSerializerOptions { WriteIndented = true }));
                    }
                    
                    // 3. Get trading account info
                    Console.WriteLine($"\n3. Getting trading account info for {firstAccountId}:");
                    var tradingAccountResponse = await client.GetAsync($"/v1/trading/accounts/{firstAccountId}/account");
                    if (tradingAccountResponse.IsSuccessStatusCode)
                    {
                        var tradingJson = await tradingAccountResponse.Content.ReadAsStringAsync();
                        var trading = JsonDocument.Parse(tradingJson);
                        Console.WriteLine(JsonSerializer.Serialize(trading, new JsonSerializerOptions { WriteIndented = true }));
                    }
                    else
                    {
                        Console.WriteLine($"Failed to get trading account: {tradingAccountResponse.StatusCode}");
                    }
                }
            }
            else
            {
                Console.WriteLine($"Failed to list accounts: {accountsResponse.StatusCode}");
                var error = await accountsResponse.Content.ReadAsStringAsync();
                Console.WriteLine($"Error: {error}");
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Exception: {ex.Message}");
        }
    }
}