using System;
using System.Text.Json;
using TraderApi.Alpaca.Models;
using TraderApi.Alpaca;

// Sample JSON from Alpaca Broker API
var json = @"{
  ""account_number"": ""920964623"",
  ""status"": ""ACTIVE"",
  ""cash"": ""24190.64"",
  ""portfolio_value"": ""24190.64"",
  ""pattern_day_trader"": false,
  ""trading_blocked"": false,
  ""transfers_blocked"": false,
  ""account_blocked"": false,
  ""buying_power"": ""24190.64""
}";

try
{
    var account = JsonSerializer.Deserialize<AlpacaAccount>(json, AlpacaJsonOptions.Default);
    Console.WriteLine($"Success! Account: {account.AccountNumber}");
    Console.WriteLine($"Cash: {account.Cash}");
    Console.WriteLine($"BuyingPower: {account.BuyingPower}");
    Console.WriteLine($"PortfolioValue: {account.PortfolioValue}");
}
catch (Exception ex)
{
    Console.WriteLine($"Error: {ex.Message}");
    Console.WriteLine($"Stack: {ex.StackTrace}");
}