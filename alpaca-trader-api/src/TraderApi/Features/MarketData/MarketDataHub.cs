using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace TraderApi.Features.MarketData;

[Authorize]
public class MarketDataHub : Hub
{
    private readonly IMarketDataService _marketDataService;
    private readonly ILogger<MarketDataHub> _logger;

    public MarketDataHub(IMarketDataService marketDataService, ILogger<MarketDataHub> logger)
    {
        _marketDataService = marketDataService;
        _logger = logger;
    }

    public override async Task OnConnectedAsync()
    {
        _logger.LogInformation("🔌 SignalR Client connected: ConnectionId={ConnectionId}, User={User}, UserAgent={UserAgent}", 
            Context.ConnectionId, 
            Context.User?.Identity?.Name ?? "Anonymous",
            Context.GetHttpContext()?.Request.Headers["User-Agent"].ToString() ?? "Unknown");
        
        // Log authentication status
        _logger.LogInformation("🔐 Client authentication status: IsAuthenticated={IsAuthenticated}, AuthType={AuthType}", 
            Context.User?.Identity?.IsAuthenticated ?? false,
            Context.User?.Identity?.AuthenticationType ?? "None");
        
        // Send connection status
        await Clients.Caller.SendAsync("ConnectionStatus", new { connected = true, connectionId = Context.ConnectionId });
        _logger.LogInformation("📤 Sent ConnectionStatus to client {ConnectionId}", Context.ConnectionId);
        
        await base.OnConnectedAsync();
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        _logger.LogInformation("🔌 SignalR Client disconnected: ConnectionId={ConnectionId}, Exception={Exception}", 
            Context.ConnectionId, exception?.Message ?? "None");
        
        // Unsubscribe from all symbols for this connection
        _logger.LogInformation("🧹 Cleaning up subscriptions for disconnected client {ConnectionId}", Context.ConnectionId);
        await _marketDataService.UnsubscribeAllAsync(Context.ConnectionId);
        
        await base.OnDisconnectedAsync(exception);
    }

    public async Task Subscribe(string symbol)
    {
        _logger.LogInformation("📥 Subscribe method called: ConnectionId={ConnectionId}, Symbol={Symbol}, User={User}", 
            Context.ConnectionId, symbol, Context.User?.Identity?.Name ?? "Anonymous");
        
        if (string.IsNullOrWhiteSpace(symbol))
        {
            _logger.LogWarning("❌ Invalid symbol provided by {ConnectionId}: '{Symbol}'", Context.ConnectionId, symbol);
            await Clients.Caller.SendAsync("Error", "Invalid symbol");
            return;
        }
        
        symbol = symbol.ToUpperInvariant();
        _logger.LogInformation("🎯 Processing subscription: ConnectionId={ConnectionId}, Symbol={Symbol}", Context.ConnectionId, symbol);
        
        try
        {
            await _marketDataService.SubscribeAsync(symbol, Context.ConnectionId);
            _logger.LogInformation("✅ Successfully subscribed {ConnectionId} to {Symbol}", Context.ConnectionId, symbol);
            
            await Clients.Caller.SendAsync("Subscribed", symbol);
            _logger.LogInformation("📤 Sent 'Subscribed' confirmation to client {ConnectionId} for {Symbol}", Context.ConnectionId, symbol);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "❌ Failed to subscribe {ConnectionId} to {Symbol}", Context.ConnectionId, symbol);
            await Clients.Caller.SendAsync("Error", $"Failed to subscribe to {symbol}: {ex.Message}");
        }
    }

    public async Task SubscribeMultiple(List<string> symbols)
    {
        if (symbols == null || !symbols.Any())
        {
            await Clients.Caller.SendAsync("Error", "No symbols provided");
            return;
        }
        
        var validSymbols = symbols
            .Where(s => !string.IsNullOrWhiteSpace(s))
            .Select(s => s.ToUpperInvariant())
            .Distinct()
            .ToList();
        
        foreach (var symbol in validSymbols)
        {
            await _marketDataService.SubscribeAsync(symbol, Context.ConnectionId);
        }
        
        await Clients.Caller.SendAsync("SubscribedMultiple", validSymbols);
    }

    public async Task Unsubscribe(string symbol)
    {
        _logger.LogInformation("📥 Unsubscribe method called: ConnectionId={ConnectionId}, Symbol={Symbol}", Context.ConnectionId, symbol);
        
        if (string.IsNullOrWhiteSpace(symbol))
        {
            _logger.LogWarning("❌ Invalid symbol for unsubscribe from {ConnectionId}", Context.ConnectionId);
            await Clients.Caller.SendAsync("Error", "Invalid symbol");
            return;
        }
        
        symbol = symbol.ToUpperInvariant();
        _logger.LogInformation("🎯 Processing unsubscription: ConnectionId={ConnectionId}, Symbol={Symbol}", Context.ConnectionId, symbol);
        
        try
        {
            await _marketDataService.UnsubscribeAsync(symbol, Context.ConnectionId);
            _logger.LogInformation("✅ Successfully unsubscribed {ConnectionId} from {Symbol}", Context.ConnectionId, symbol);
            
            await Clients.Caller.SendAsync("Unsubscribed", symbol);
            _logger.LogInformation("📤 Sent 'Unsubscribed' confirmation to client {ConnectionId} for {Symbol}", Context.ConnectionId, symbol);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "❌ Failed to unsubscribe {ConnectionId} from {Symbol}", Context.ConnectionId, symbol);
        }
    }

    public async Task UnsubscribeAll()
    {
        await _marketDataService.UnsubscribeAllAsync(Context.ConnectionId);
        await Clients.Caller.SendAsync("UnsubscribedAll");
    }
}