using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace TraderApi.Features.MarketData;

public static class MarketDataEndpoints
{
    public static void MapMarketDataEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/market-data")
            .RequireAuthorization();

        // Get market data service status
        group.MapGet("/status", [Authorize] (IMarketDataService marketDataService, ILogger<Program> logger) =>
        {
            var alpacaService = marketDataService as AlpacaMarketDataService;
            var subscriptionInfo = alpacaService?.GetSubscriptionInfo() ?? new Dictionary<string, object>();
            
            logger.LogInformation("📊 Market data status requested. Connected: {Connected}", marketDataService.IsConnected);
            
            return Results.Ok(new
            {
                connected = marketDataService.IsConnected,
                timestamp = DateTime.UtcNow,
                subscriptions = subscriptionInfo
            });
        });

        // Test endpoint to simulate quote updates (development only)
        if (app is WebApplication webApp && webApp.Environment.IsDevelopment())
        {
            group.MapPost("/test-quote", [Authorize] async (string symbol, IHubContext<MarketDataHub> hubContext) =>
            {
                var random = new Random();
                var basePrice = 150m + (decimal)(random.NextDouble() * 10);
                var spread = 0.01m;
                
                var testQuote = new Quote
                {
                    Symbol = symbol.ToUpperInvariant(),
                    Price = basePrice,
                    BidPrice = basePrice - spread,
                    AskPrice = basePrice + spread,
                    BidSize = random.Next(100, 1000),
                    AskSize = random.Next(100, 1000),
                    Volume = random.Next(1000000, 10000000),
                    Timestamp = DateTime.UtcNow,
                    Change = (decimal)(random.NextDouble() * 4 - 2),
                    ChangePercent = (decimal)(random.NextDouble() * 3 - 1.5),
                    DayHigh = basePrice + (decimal)(random.NextDouble() * 5),
                    DayLow = basePrice - (decimal)(random.NextDouble() * 5),
                    PreviousClose = basePrice - (decimal)(random.NextDouble() * 2 - 1)
                };

                // Send to all connected clients
                await hubContext.Clients.All.SendAsync("QuoteUpdate", testQuote);
                
                return Results.Ok(new { message = "Test quote sent", quote = testQuote });
            });
        }

        // Map SignalR hub with proper authorization
        app.MapHub<MarketDataHub>("/hubs/market-data")
            .RequireAuthorization(); // Ensure hub requires authorization
    }
}