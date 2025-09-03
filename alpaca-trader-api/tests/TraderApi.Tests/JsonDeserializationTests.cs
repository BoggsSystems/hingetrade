using System.Text.Json;
using TraderApi.Alpaca;
using TraderApi.Alpaca.Models;
using Xunit;

namespace TraderApi.Tests;

public class JsonDeserializationTests
{
    [Fact]
    public void Should_Deserialize_AlpacaAccount_With_String_Decimals()
    {
        // Arrange
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

        // Act
        var account = JsonSerializer.Deserialize<AlpacaAccount>(json, AlpacaJsonOptions.Default);

        // Assert
        Assert.NotNull(account);
        Assert.Equal("920964623", account.AccountNumber);
        Assert.Equal("ACTIVE", account.Status);
        Assert.Equal(24190.64m, account.Cash);
        Assert.Equal(24190.64m, account.PortfolioValue);
        Assert.Equal(24190.64m, account.BuyingPower);
        Assert.False(account.PatternDayTrader);
        Assert.False(account.TradingBlocked);
        Assert.False(account.TransfersBlocked);
        Assert.False(account.AccountBlocked);
    }
}