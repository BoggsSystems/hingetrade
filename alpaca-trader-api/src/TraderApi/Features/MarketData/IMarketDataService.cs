namespace TraderApi.Features.MarketData;

public interface IMarketDataService
{
    Task StartAsync();
    Task StopAsync();
    Task SubscribeAsync(string symbol, string connectionId);
    Task UnsubscribeAsync(string symbol, string connectionId);
    Task UnsubscribeAllAsync(string connectionId);
    bool IsConnected { get; }
}