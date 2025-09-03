using System.Net.WebSockets;
using System.Text;
using System.Text.Json;
using TraderApi.Alpaca.Models;

namespace TraderApi.Alpaca;

public interface IAlpacaStreamingClient
{
    Task ConnectAsync(string apiKeyId, string apiSecret);
    Task SubscribeQuotesAsync(List<string> symbols);
    Task UnsubscribeQuotesAsync(List<string> symbols);
    event EventHandler<AlpacaQuote>? QuoteReceived;
    Task DisconnectAsync();
}

public class AlpacaStreamingClient : IAlpacaStreamingClient, IDisposable
{
    private readonly ILogger<AlpacaStreamingClient> _logger;
    private readonly AlpacaSettings _settings;
    private ClientWebSocket? _webSocket;
    private CancellationTokenSource? _cancellationTokenSource;
    private Task? _receiveLoopTask;
    
    public event EventHandler<AlpacaQuote>? QuoteReceived;

    public AlpacaStreamingClient(ILogger<AlpacaStreamingClient> logger, AlpacaSettings settings)
    {
        _logger = logger;
        _settings = settings;
    }

    public async Task ConnectAsync(string apiKeyId, string apiSecret)
    {
        _webSocket = new ClientWebSocket();
        _cancellationTokenSource = new CancellationTokenSource();
        
        await _webSocket.ConnectAsync(new Uri(_settings.MarketDataUrl), _cancellationTokenSource.Token);
        
        // Start receive loop
        _receiveLoopTask = Task.Run(async () => await ReceiveLoop(_cancellationTokenSource.Token));
        
        // Authenticate
        var authMessage = new
        {
            action = "auth",
            key = apiKeyId,
            secret = apiSecret
        };
        
        await SendMessageAsync(authMessage);
    }

    public async Task SubscribeQuotesAsync(List<string> symbols)
    {
        if (_webSocket?.State != WebSocketState.Open)
            throw new InvalidOperationException("WebSocket is not connected");
        
        var message = new
        {
            action = "subscribe",
            quotes = symbols
        };
        
        await SendMessageAsync(message);
    }

    public async Task UnsubscribeQuotesAsync(List<string> symbols)
    {
        if (_webSocket?.State != WebSocketState.Open)
            throw new InvalidOperationException("WebSocket is not connected");
        
        var message = new
        {
            action = "unsubscribe",
            quotes = symbols
        };
        
        await SendMessageAsync(message);
    }

    private async Task SendMessageAsync(object message)
    {
        var json = JsonSerializer.Serialize(message);
        var bytes = Encoding.UTF8.GetBytes(json);
        await _webSocket!.SendAsync(new ArraySegment<byte>(bytes), WebSocketMessageType.Text, true, CancellationToken.None);
    }

    private async Task ReceiveLoop(CancellationToken cancellationToken)
    {
        var buffer = new ArraySegment<byte>(new byte[4096]);
        
        while (!cancellationToken.IsCancellationRequested && _webSocket?.State == WebSocketState.Open)
        {
            try
            {
                var result = await _webSocket.ReceiveAsync(buffer, cancellationToken);
                
                if (result.MessageType == WebSocketMessageType.Text)
                {
                    var json = Encoding.UTF8.GetString(buffer.Array!, 0, result.Count);
                    ProcessMessage(json);
                }
                else if (result.MessageType == WebSocketMessageType.Close)
                {
                    await _webSocket.CloseAsync(WebSocketCloseStatus.NormalClosure, string.Empty, cancellationToken);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in WebSocket receive loop");
            }
        }
    }

    private void ProcessMessage(string json)
    {
        try
        {
            var messageDoc = JsonDocument.Parse(json);
            
            if (messageDoc.RootElement.TryGetProperty("T", out var typeElement))
            {
                var messageType = typeElement.GetString();
                
                if (messageType == "q") // Quote message
                {
                    var quote = JsonSerializer.Deserialize<AlpacaQuote>(json);
                    if (quote != null)
                    {
                        QuoteReceived?.Invoke(this, quote);
                    }
                }
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing WebSocket message: {Message}", json);
        }
    }

    public async Task DisconnectAsync()
    {
        _cancellationTokenSource?.Cancel();
        
        if (_webSocket?.State == WebSocketState.Open)
        {
            await _webSocket.CloseAsync(WebSocketCloseStatus.NormalClosure, string.Empty, CancellationToken.None);
        }
        
        if (_receiveLoopTask != null)
        {
            await _receiveLoopTask;
        }
    }

    public void Dispose()
    {
        _cancellationTokenSource?.Dispose();
        _webSocket?.Dispose();
    }
}