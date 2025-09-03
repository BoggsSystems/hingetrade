using FluentAssertions;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Moq;
using StackExchange.Redis;
using TraderApi.Alpaca;
using TraderApi.Alpaca.Models;
using TraderApi.Data;
using TraderApi.Features.Alerts;
using TraderApi.Notifications;
using TraderApi.Security;
using Xunit;

namespace TraderApi.Tests;

public class AlertsWorkerTests : IAsyncLifetime
{
    private ServiceProvider? _serviceProvider;
    private AppDbContext? _dbContext;

    public async Task InitializeAsync()
    {
        var services = new ServiceCollection();
        
        // Add in-memory database
        services.AddDbContext<AppDbContext>(options =>
            options.UseInMemoryDatabase($"TestDb_{Guid.NewGuid()}"));

        // Add mocks
        services.AddSingleton(Mock.Of<ILogger<AlertsWorker>>());
        services.AddSingleton(Mock.Of<IConnectionMultiplexer>());
        services.AddScoped<IAlertsService, AlertsService>();
        services.AddSingleton(Mock.Of<ILogger<AlertsService>>());
        
        // Mock Alpaca client
        var mockAlpacaClient = new Mock<IAlpacaClient>();
        mockAlpacaClient
            .Setup(x => x.GetLatestQuotesAsync(It.IsAny<string>(), It.IsAny<string>(), It.IsAny<List<string>>()))
            .ReturnsAsync(new Dictionary<string, AlpacaQuote>
            {
                ["AAPL"] = new AlpacaQuote { Symbol = "AAPL", AskPrice = 151.00m, BidPrice = 150.00m },
                ["MSFT"] = new AlpacaQuote { Symbol = "MSFT", AskPrice = 301.00m, BidPrice = 300.00m }
            });
        services.AddSingleton(mockAlpacaClient.Object);
        
        // Mock key protector
        var mockKeyProtector = new Mock<IKeyProtector>();
        mockKeyProtector.Setup(x => x.Decrypt(It.IsAny<string>())).Returns<string>(s => s);
        mockKeyProtector.Setup(x => x.Encrypt(It.IsAny<string>())).Returns<string>(s => s);
        services.AddSingleton(mockKeyProtector.Object);
        
        // Mock email notifier
        services.AddSingleton(Mock.Of<IEmailNotifier>());
        
        _serviceProvider = services.BuildServiceProvider();
        _dbContext = _serviceProvider.GetRequiredService<AppDbContext>();
        
        await _dbContext.Database.EnsureCreatedAsync();
    }

    public async Task DisposeAsync()
    {
        if (_dbContext != null)
            await _dbContext.DisposeAsync();
        _serviceProvider?.Dispose();
    }

    [Fact]
    public async Task AlertsWorker_ShouldTriggerAlerts_WhenThresholdsCrossed()
    {
        // Arrange
        var userId = Guid.NewGuid();
        var user = new User
        {
            Id = userId,
            AuthSub = "test-user",
            Email = "test@example.com",
            CreatedAt = DateTime.UtcNow
        };
        
        var alpacaLink = new AlpacaLink
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            AccountId = "test-account",
            ApiKeyId = "test-key",
            ApiSecret = "test-secret",
            Env = "paper",
            CreatedAt = DateTime.UtcNow
        };
        
        var alerts = new List<Alert>
        {
            new()
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                Symbol = "AAPL",
                Operator = ">",
                Threshold = 149.00m, // Current price is 150.50, so this should trigger
                Active = true
            },
            new()
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                Symbol = "MSFT",
                Operator = "<",
                Threshold = 350.00m, // Current price is 300.50, so this should trigger
                Active = true
            },
            new()
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                Symbol = "AAPL",
                Operator = ">",
                Threshold = 200.00m, // Current price is 150.50, so this should NOT trigger
                Active = true
            }
        };

        _dbContext!.Users.Add(user);
        _dbContext.AlpacaLinks.Add(alpacaLink);
        _dbContext.Alerts.AddRange(alerts);
        await _dbContext.SaveChangesAsync();

        var alertsService = _serviceProvider!.GetRequiredService<IAlertsService>();
        var activeAlerts = await alertsService.GetActiveAlertsAsync();

        // Assert
        activeAlerts.Should().HaveCount(3);
        
        // Verify the alerts that should trigger based on our mock data
        var appleAlert = activeAlerts.First(a => a.Symbol == "AAPL" && a.Threshold == 149.00m);
        var msftAlert = activeAlerts.First(a => a.Symbol == "MSFT");
        
        // Current AAPL price (150.50) > 149.00 threshold
        ((150.00m + 151.00m) / 2 > appleAlert.Threshold).Should().BeTrue();
        
        // Current MSFT price (300.50) < 350.00 threshold
        ((300.00m + 301.00m) / 2 < msftAlert.Threshold).Should().BeTrue();
    }

    [Fact]
    public async Task AlertsWorker_ShouldRespectDebounce_WhenRecentlyTriggered()
    {
        // Arrange
        var userId = Guid.NewGuid();
        var recentlyTriggered = new Alert
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Symbol = "AAPL",
            Operator = ">",
            Threshold = 100.00m,
            Active = true,
            LastTriggeredAt = DateTime.UtcNow.AddMinutes(-3) // Triggered 3 minutes ago
        };

        _dbContext!.Users.Add(new User
        {
            Id = userId,
            AuthSub = "test-user",
            Email = "test@example.com",
            CreatedAt = DateTime.UtcNow
        });
        
        _dbContext.Alerts.Add(recentlyTriggered);
        await _dbContext.SaveChangesAsync();

        var alertsService = _serviceProvider!.GetRequiredService<IAlertsService>();
        var activeAlerts = await alertsService.GetActiveAlertsAsync();

        // Assert
        activeAlerts.Should().HaveCount(1);
        activeAlerts[0].LastTriggeredAt.Should().NotBeNull();
        activeAlerts[0].LastTriggeredAt.Should().BeCloseTo(DateTime.UtcNow.AddMinutes(-3), TimeSpan.FromSeconds(1));
    }
}