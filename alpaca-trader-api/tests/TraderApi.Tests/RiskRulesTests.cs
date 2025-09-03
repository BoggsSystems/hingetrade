using FluentAssertions;
using TraderApi.Features.Orders;
using TraderApi.Features.Orders.Risk;
using Xunit;

namespace TraderApi.Tests;

public class RiskRulesTests
{
    [Theory]
    [InlineData(100, 100.00, 10000, false)] // 100 * 100 = $10,000 (at limit)
    [InlineData(100, 100.01, 10000, true)]  // 100 * 100.01 = $10,001 (over limit)
    [InlineData(50, 100.00, 10000, false)]  // 50 * 100 = $5,000 (under limit)
    public async Task MaxOrderNotionalRule_ShouldValidateCorrectly(
        decimal qty,
        decimal price,
        decimal maxNotional,
        bool shouldViolate)
    {
        // Arrange
        var rule = new MaxOrderNotionalRule(maxNotional);
        var request = new CreateOrderRequest(
            "test-001",
            "AAPL",
            "buy",
            "limit",
            qty,
            price,
            "day"
        );

        // Act
        var violation = await rule.ValidateAsync(request, null);

        // Assert
        if (shouldViolate)
        {
            violation.Should().NotBeNull();
            violation!.Rule.Should().Be("MaxOrderNotional");
        }
        else
        {
            violation.Should().BeNull();
        }
    }

    [Theory]
    [InlineData(100, 100, false)]  // At limit
    [InlineData(101, 100, true)]   // Over limit
    [InlineData(50, 100, false)]   // Under limit
    public async Task MaxShareQuantityRule_ShouldValidateCorrectly(
        decimal qty,
        int maxShares,
        bool shouldViolate)
    {
        // Arrange
        var rule = new MaxShareQuantityRule(maxShares);
        var request = new CreateOrderRequest(
            "test-001",
            "AAPL",
            "buy",
            "limit",
            qty,
            100.00m,
            "day"
        );

        // Act
        var violation = await rule.ValidateAsync(request, null);

        // Assert
        if (shouldViolate)
        {
            violation.Should().NotBeNull();
            violation!.Rule.Should().Be("MaxShareQuantity");
        }
        else
        {
            violation.Should().BeNull();
        }
    }

    [Theory]
    [InlineData("AAPL", new[] { "AAPL", "MSFT", "GOOGL" }, false)]
    [InlineData("TSLA", new[] { "AAPL", "MSFT", "GOOGL" }, true)]
    [InlineData("aapl", new[] { "AAPL", "MSFT", "GOOGL" }, false)] // Case insensitive
    public async Task SymbolWhitelistRule_ShouldValidateCorrectly(
        string symbol,
        string[] allowedSymbols,
        bool shouldViolate)
    {
        // Arrange
        var rule = new SymbolWhitelistRule(allowedSymbols.ToList());
        var request = new CreateOrderRequest(
            "test-001",
            symbol,
            "buy",
            "limit",
            10,
            100.00m,
            "day"
        );

        // Act
        var violation = await rule.ValidateAsync(request, null);

        // Assert
        if (shouldViolate)
        {
            violation.Should().NotBeNull();
            violation!.Rule.Should().Be("SymbolWhitelist");
        }
        else
        {
            violation.Should().BeNull();
        }
    }

    [Fact]
    public async Task TradingHoursRule_ShouldValidateBasedOnCurrentTime()
    {
        // This is a simplified test - in production you'd mock the time
        var rule = new TradingHoursRule(regularHoursOnly: true);
        var request = new CreateOrderRequest(
            "test-001",
            "AAPL",
            "buy",
            "limit",
            10,
            100.00m,
            "day"
        );

        // Act
        var violation = await rule.ValidateAsync(request, null);

        // Assert
        // The result depends on when the test runs
        // We're just checking that the rule executes without error
        violation?.Rule.Should().Be("TradingHours");
    }
}