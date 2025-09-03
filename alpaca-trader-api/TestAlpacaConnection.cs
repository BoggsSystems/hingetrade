using System;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Threading.Tasks;

class TestAlpacaConnection
{
    static async Task Main(string[] args)
    {
        var apiKeyId = "CKB4051UELTQZSUS78S8";
        var apiSecret = "ZdjZPMzxPcAf7aWngyC1UtHJfHdRjvssxIvCJTlA";
        var baseUrl = "https://paper-api.alpaca.markets";

        using var client = new HttpClient();
        client.BaseAddress = new Uri(baseUrl);
        client.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
        client.DefaultRequestHeaders.Add("APCA-API-KEY-ID", apiKeyId);
        client.DefaultRequestHeaders.Add("APCA-API-SECRET-KEY", apiSecret);

        try
        {
            Console.WriteLine("Testing Alpaca API connection...");
            
            // Test account endpoint
            var response = await client.GetAsync("/v2/account");
            
            if (response.IsSuccessStatusCode)
            {
                var content = await response.Content.ReadAsStringAsync();
                Console.WriteLine("✅ Success! Connected to Alpaca Paper Trading API");
                Console.WriteLine("Account Info:");
                Console.WriteLine(content);
            }
            else
            {
                Console.WriteLine($"❌ Failed: {response.StatusCode} - {response.ReasonPhrase}");
                var error = await response.Content.ReadAsStringAsync();
                Console.WriteLine($"Error: {error}");
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"❌ Exception: {ex.Message}");
        }
    }
}