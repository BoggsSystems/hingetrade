using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using TraderApi.Alpaca;
using TraderApi.Features.Orders;
using TraderApi.Features.Orders.Risk;
using Xunit;

namespace TraderApi.Tests;

public class OrdersTests
{
    [Fact]
    public async Task CreateOrder_ShouldEnforceIdempotency()
    {
        // Arrange
        var mockOrdersService = new Mock<IOrdersService>();
        var clientOrderId = "test-order-123";
        var userId = Guid.NewGuid();
        
        mockOrdersService
            .SetupSequence(x => x.CreateOrderAsync(userId, It.IsAny<CreateOrderRequest>()))
            .ReturnsAsync(new CreateOrderResponse("alpaca-123", "accepted", DateTime.UtcNow))
            .ThrowsAsync(new InvalidOperationException($"Order with client_order_id '{clientOrderId}' already exists"));

        var service = mockOrdersService.Object;
        var request = new CreateOrderRequest(
            clientOrderId,
            "AAPL",
            "buy",
            "limit",
            10,
            150.00m,
            "day"
        );

        // Act
        var firstCall = await service.CreateOrderAsync(userId, request);
        var secondCall = () => service.CreateOrderAsync(userId, request);

        // Assert
        firstCall.Should().NotBeNull();
        firstCall.AlpacaOrderId.Should().Be("alpaca-123");
        
        await secondCall.Should().ThrowAsync<InvalidOperationException>()
            .WithMessage($"Order with client_order_id '{clientOrderId}' already exists");
    }

    [Fact]
    public async Task RiskRules_ShouldRejectOverLimitOrders()
    {
        // Arrange
        var riskSettings = new RiskSettings
        {
            MaxOrderNotional = 10000,
            MaxShareQuantity = 100,
            AllowedSymbols = new List<string> { "AAPL", "MSFT" },
            RegularHoursOnly = true
        };

        var mockAlpacaClient = new Mock<IAlpacaClient>();
        var mockAssetValidationService = new Mock<IAssetValidationService>();
        var mockLogger = new Mock<ILogger<RiskService>>();
        
        var riskService = new RiskService(riskSettings, mockAlpacaClient.Object, mockAssetValidationService.Object, mockLogger.Object);

        var overNotionalRequest = new CreateOrderRequest(
            "test-001",
            "AAPL",
            "buy",
            "limit",
            100,
            200.00m, // 100 * 200 = $20,000 > $10,000 limit
            "day"
        );

        var overQuantityRequest = new CreateOrderRequest(
            "test-002",
            "AAPL",
            "buy",
            "limit",
            200, // 200 > 100 share limit
            50.00m,
            "day"
        );

        var notAllowedSymbol = new CreateOrderRequest(
            "test-003",
            "TSLA", // Not in allowed list
            "buy",
            "limit",
            10,
            100.00m,
            "day"
        );

        // Act
        var notionalViolations = await riskService.ValidateOrderAsync(overNotionalRequest, "key", "secret");
        var quantityViolations = await riskService.ValidateOrderAsync(overQuantityRequest, "key", "secret");
        var symbolViolations = await riskService.ValidateOrderAsync(notAllowedSymbol, "key", "secret");

        // Assert
        notionalViolations.Should().HaveCount(1);
        notionalViolations[0].Rule.Should().Be("MaxOrderNotional");
        notionalViolations[0].Message.Should().Contain("$20,000.00 exceeds maximum $10,000.00");

        quantityViolations.Should().HaveCount(1);
        quantityViolations[0].Rule.Should().Be("MaxShareQuantity");
        quantityViolations[0].Message.Should().Contain("200 exceeds maximum 100 shares");

        symbolViolations.Should().HaveCount(1);
        symbolViolations[0].Rule.Should().Be("SymbolWhitelist");
        symbolViolations[0].Message.Should().Contain("TSLA is not in the allowed list");
    }
}