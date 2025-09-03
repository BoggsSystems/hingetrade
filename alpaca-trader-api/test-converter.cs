using System;
using System.Text.Json;
using System.Text.Json.Serialization;
using TraderApi.Alpaca.JsonConverters;
using TraderApi.Alpaca.Models;

var json = @"{""buying_power"": ""24190.64"", ""cash"": ""24190.64"", ""portfolio_value"": ""24190.64"", ""account_number"": ""920964623"", ""status"": ""ACTIVE"", ""pattern_day_trader"": false, ""trading_blocked"": false, ""transfers_blocked"": false, ""account_blocked"": false}";

var options = new JsonSerializerOptions
{
    PropertyNameCaseInsensitive = true
};

try
{
    var account = JsonSerializer.Deserialize<AlpacaAccount>(json, options);
    Console.WriteLine($"BuyingPower: {account.BuyingPower}");
    Console.WriteLine($"Cash: {account.Cash}");
    Console.WriteLine("Success!");
}
catch (Exception ex)
{
    Console.WriteLine($"Error: {ex.Message}");
    Console.WriteLine($"Stack: {ex.StackTrace}");
}