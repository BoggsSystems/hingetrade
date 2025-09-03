using Microsoft.EntityFrameworkCore;
using StackExchange.Redis;
using TraderApi.Alpaca;
using TraderApi.Data;
using TraderApi.Notifications;
using TraderApi.Security;

namespace TraderApi.Features.Alerts;

public class AlertsWorker : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<AlertsWorker> _logger;
    private readonly IConnectionMultiplexer _redis;
    private readonly TimeSpan _pollInterval = TimeSpan.FromSeconds(10);
    private readonly Dictionary<string, decimal> _lastPrices = new();

    public AlertsWorker(
        IServiceProvider serviceProvider,
        ILogger<AlertsWorker> logger,
        IConnectionMultiplexer redis)
    {
        _serviceProvider = serviceProvider;
        _logger = logger;
        _redis = redis;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("Alerts Worker started");

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await ProcessAlertsAsync(stoppingToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing alerts");
            }

            await Task.Delay(_pollInterval, stoppingToken);
        }

        _logger.LogInformation("Alerts Worker stopped");
    }

    private async Task ProcessAlertsAsync(CancellationToken cancellationToken)
    {
        // Use distributed lock to prevent concurrent processing
        var db = _redis.GetDatabase();
        var lockKey = "alerts:tick";
        var lockToken = Guid.NewGuid().ToString();
        
        if (!await db.LockTakeAsync(lockKey, lockToken, TimeSpan.FromSeconds(30)))
        {
            _logger.LogDebug("Another instance is processing alerts");
            return;
        }

        try
        {
            using var scope = _serviceProvider.CreateScope();
            var alertsService = scope.ServiceProvider.GetRequiredService<IAlertsService>();
            var dbContext = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            var alpacaClient = scope.ServiceProvider.GetRequiredService<IAlpacaClient>();
            var keyProtector = scope.ServiceProvider.GetRequiredService<IKeyProtector>();
            var emailNotifier = scope.ServiceProvider.GetRequiredService<IEmailNotifier>();

            // Get all active alerts
            var activeAlerts = await alertsService.GetActiveAlertsAsync();
            
            if (!activeAlerts.Any())
            {
                return;
            }

            // Group alerts by user to minimize API calls
            var alertsByUser = activeAlerts.GroupBy(a => a.UserId);

            foreach (var userAlerts in alertsByUser)
            {
                try
                {
                    await ProcessUserAlertsAsync(
                        userAlerts.Key,
                        userAlerts.ToList(),
                        dbContext,
                        alpacaClient,
                        keyProtector,
                        alertsService,
                        emailNotifier,
                        cancellationToken);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error processing alerts for user {UserId}", userAlerts.Key);
                }
            }
        }
        finally
        {
            await db.LockReleaseAsync(lockKey, lockToken);
        }
    }

    private async Task ProcessUserAlertsAsync(
        Guid userId,
        List<Alert> alerts,
        AppDbContext dbContext,
        IAlpacaClient alpacaClient,
        IKeyProtector keyProtector,
        IAlertsService alertsService,
        IEmailNotifier emailNotifier,
        CancellationToken cancellationToken)
    {
        // Get user's Alpaca credentials
        var alpacaLink = await dbContext.AlpacaLinks
            .FirstOrDefaultAsync(al => al.UserId == userId, cancellationToken);
            
        if (alpacaLink == null)
        {
            _logger.LogWarning("No Alpaca link found for user {UserId}", userId);
            return;
        }

        var apiKeyId = keyProtector.Decrypt(alpacaLink.ApiKeyId);
        var apiSecret = keyProtector.Decrypt(alpacaLink.ApiSecret);

        // Get unique symbols
        var symbols = alerts.Select(a => a.Symbol).Distinct().ToList();
        
        // Fetch current quotes
        var quotes = await alpacaClient.GetLatestQuotesAsync(apiKeyId, apiSecret, symbols);

        foreach (var alert in alerts)
        {
            if (!quotes.TryGetValue(alert.Symbol, out var quote))
            {
                continue;
            }

            var currentPrice = (quote.AskPrice + quote.BidPrice) / 2;
            var triggered = false;

            // Store previous price for crosses operators
            var hadPreviousPrice = _lastPrices.TryGetValue($"{userId}:{alert.Symbol}", out var previousPrice);
            
            switch (alert.Operator)
            {
                case ">":
                    triggered = currentPrice > alert.Threshold;
                    break;
                case "<":
                    triggered = currentPrice < alert.Threshold;
                    break;
                case ">=":
                    triggered = currentPrice >= alert.Threshold;
                    break;
                case "<=":
                    triggered = currentPrice <= alert.Threshold;
                    break;
                case "crosses_up":
                    triggered = hadPreviousPrice && previousPrice <= alert.Threshold && currentPrice > alert.Threshold;
                    break;
                case "crosses_down":
                    triggered = hadPreviousPrice && previousPrice >= alert.Threshold && currentPrice < alert.Threshold;
                    break;
            }

            // Update last price
            _lastPrices[$"{userId}:{alert.Symbol}"] = currentPrice;

            if (triggered)
            {
                // Check debounce (don't trigger if recently triggered)
                if (alert.LastTriggeredAt.HasValue && 
                    DateTime.UtcNow - alert.LastTriggeredAt.Value < TimeSpan.FromMinutes(5))
                {
                    continue;
                }

                _logger.LogInformation(
                    "Alert triggered for user {UserId}: {Symbol} {Operator} {Threshold}, current price: {CurrentPrice}",
                    userId, alert.Symbol, alert.Operator, alert.Threshold, currentPrice);

                // Mark as triggered
                await alertsService.MarkAlertTriggeredAsync(alert.Id);

                // Send notification
                await emailNotifier.SendAlertTriggeredAsync(
                    alert.User.Email,
                    alert.Symbol,
                    alert.Operator,
                    alert.Threshold,
                    currentPrice);
            }
        }
    }
}