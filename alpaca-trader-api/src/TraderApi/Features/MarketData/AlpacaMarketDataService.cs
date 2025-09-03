using System.Collections.Concurrent;
using System.Net.WebSockets;
using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.SignalR;

namespace TraderApi.Features.MarketData;

public class AlpacaMarketDataService : IMarketDataService, IHostedService
{
    private readonly ILogger<AlpacaMarketDataService> _logger;
    private readonly IConfiguration _configuration;
    private readonly IHubContext<MarketDataHub> _hubContext;
    private readonly IMarketDataRestClient _marketDataRestClient;
    private readonly IYahooFinanceClient _yahooFinanceClient;
    
    private ClientWebSocket? _webSocket;
    private CancellationTokenSource? _cancellationTokenSource;
    private Task? _receiveTask;
    
    // Track subscriptions: Symbol -> Set of ConnectionIds
    private readonly ConcurrentDictionary<string, HashSet<string>> _subscriptions = new();
    
    // Track connection subscriptions: ConnectionId -> Set of Symbols
    private readonly ConcurrentDictionary<string, HashSet<string>> _connectionSubscriptions = new();
    
    // Store latest quotes for new subscribers
    private readonly ConcurrentDictionary<string, Quote> _latestQuotes = new();
    
    private readonly string _apiKey;
    private readonly string _apiSecret;
    private readonly string _webSocketUrl;
    
    public bool IsConnected => _webSocket?.State == WebSocketState.Open;
    
    public Dictionary<string, object> GetSubscriptionInfo()
    {
        return new Dictionary<string, object>
        {
            ["totalSymbols"] = _subscriptions.Count,
            ["totalConnections"] = _connectionSubscriptions.Count,
            ["symbols"] = _subscriptions.ToDictionary(kvp => kvp.Key, kvp => kvp.Value.Count),
            ["webSocketState"] = _webSocket?.State.ToString() ?? "null",
            ["cachedQuotes"] = _latestQuotes.Count
        };
    }

    public AlpacaMarketDataService(
        ILogger<AlpacaMarketDataService> logger,
        IConfiguration configuration,
        IHubContext<MarketDataHub> hubContext,
        IMarketDataRestClient marketDataRestClient,
        IYahooFinanceClient yahooFinanceClient)
    {
        _logger = logger;
        _configuration = configuration;
        _hubContext = hubContext;
        _marketDataRestClient = marketDataRestClient;
        _yahooFinanceClient = yahooFinanceClient;
        
        _apiKey = configuration["ALPACA_API_KEY_ID"] ?? configuration["Alpaca:ApiKeyId"] ?? throw new InvalidOperationException("ALPACA_API_KEY_ID not configured");
        _apiSecret = configuration["ALPACA_API_SECRET"] ?? configuration["Alpaca:ApiSecret"] ?? throw new InvalidOperationException("ALPACA_API_SECRET not configured");
        
        // Always use IEX feed for free tier
        _webSocketUrl = configuration["ALPACA_ENV"]?.ToLower() == "live" 
            ? "wss://stream.data.alpaca.markets/v2/iex"
            : "wss://stream.data.sandbox.alpaca.markets/v2/iex";
    }

    public async Task StartAsync()
    {
        await StartAsync(CancellationToken.None);
    }
    
    public async Task StartAsync(CancellationToken cancellationToken)
    {
        _logger.LogInformation("🚀 Starting Alpaca Market Data Service");
        _logger.LogInformation("📊 Configuration: Environment={Environment}, WebSocketUrl={WebSocketUrl}", 
            _configuration["ALPACA_ENV"] ?? _configuration["Alpaca:Env"] ?? "sandbox",
            _webSocketUrl);
        await ConnectAsync();
    }

    public async Task StopAsync()
    {
        await StopAsync(CancellationToken.None);
    }
    
    public async Task StopAsync(CancellationToken cancellationToken)
    {
        _logger.LogInformation("Stopping Alpaca Market Data Service");
        _cancellationTokenSource?.Cancel();
        
        if (_webSocket?.State == WebSocketState.Open)
        {
            await _webSocket.CloseAsync(WebSocketCloseStatus.NormalClosure, "Stopping service", cancellationToken);
        }
        
        _webSocket?.Dispose();
        
        if (_receiveTask != null)
        {
            await _receiveTask;
        }
    }

    private async Task ConnectAsync()
    {
        try
        {
            _cancellationTokenSource = new CancellationTokenSource();
            _webSocket = new ClientWebSocket();
            
            _logger.LogInformation("🔗 Connecting to Alpaca WebSocket at {Url}", _webSocketUrl);
            _logger.LogInformation("🔑 Using API Key: {ApiKeyPrefix}...", _apiKey?.Substring(0, Math.Min(10, _apiKey?.Length ?? 0)));
            
            await _webSocket.ConnectAsync(new Uri(_webSocketUrl), _cancellationTokenSource.Token);
            _logger.LogInformation("✅ WebSocket connected successfully. State: {State}", _webSocket.State);
            
            // Start receive loop
            _receiveTask = ReceiveLoop(_cancellationTokenSource.Token);
            _logger.LogInformation("🔄 Started WebSocket receive loop");
            
            // Authenticate
            await AuthenticateAsync();
            
            _logger.LogInformation("🎉 Successfully connected to Alpaca Market Data WebSocket");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "❌ Failed to connect to Alpaca WebSocket at {Url}", _webSocketUrl);
            _logger.LogInformation("⏳ Will retry connection in 5 seconds...");
            // Retry connection after delay
            _ = Task.Delay(5000).ContinueWith(async _ => await ConnectAsync());
        }
    }

    private async Task AuthenticateAsync()
    {
        _logger.LogInformation("🔐 Authenticating with Alpaca WebSocket");
        
        var authMessage = new AlpacaAuthMessage
        {
            Action = "auth",
            Key = _apiKey,
            Secret = _apiSecret
        };
        
        await SendMessageAsync(authMessage);
        _logger.LogInformation("🔐 Authentication message sent");
    }

    private async Task ReceiveLoop(CancellationToken cancellationToken)
    {
        var buffer = new ArraySegment<byte>(new byte[4096]);
        var messageBuilder = new StringBuilder();
        
        while (!cancellationToken.IsCancellationRequested && _webSocket?.State == WebSocketState.Open)
        {
            try
            {
                WebSocketReceiveResult result;
                messageBuilder.Clear();
                
                do
                {
                    result = await _webSocket.ReceiveAsync(buffer, cancellationToken);
                    
                    if (result.MessageType == WebSocketMessageType.Text)
                    {
                        messageBuilder.Append(Encoding.UTF8.GetString(buffer.Array!, 0, result.Count));
                    }
                    else if (result.MessageType == WebSocketMessageType.Close)
                    {
                        _logger.LogWarning("WebSocket closed by server");
                        await HandleDisconnection();
                        return;
                    }
                } while (!result.EndOfMessage);
                
                var message = messageBuilder.ToString();
                await ProcessMessage(message);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in receive loop");
                await HandleDisconnection();
            }
        }
    }

    private async Task ProcessMessage(string message)
    {
        try
        {
            _logger.LogDebug("📨 Raw message from Alpaca: {Message}", message.Length > 500 ? message.Substring(0, 500) + "..." : message);
            
            // Alpaca sends arrays of messages
            var messages = JsonSerializer.Deserialize<JsonElement[]>(message);
            if (messages == null) 
            {
                _logger.LogWarning("⚠️ Received null or invalid message from Alpaca");
                return;
            }
            
            _logger.LogInformation("📦 Processing {Count} messages from Alpaca", messages.Length);
            
            foreach (var msg in messages)
            {
                var type = msg.GetProperty("T").GetString();
                _logger.LogInformation("📋 Processing message type: {Type}", type);
                
                switch (type)
                {
                    case "success":
                        var successMsg = JsonSerializer.Deserialize<AlpacaStreamMessage>(msg.GetRawText());
                        _logger.LogInformation("✅ Alpaca WebSocket success: {Message}", successMsg?.Message);
                        break;
                        
                    case "error":
                        var errorMsg = JsonSerializer.Deserialize<AlpacaStreamMessage>(msg.GetRawText());
                        _logger.LogError("❌ Alpaca WebSocket error: {Message} (Code: {Code})", errorMsg?.Message, errorMsg?.Code);
                        break;
                        
                    case "q": // Quote
                        var quote = JsonSerializer.Deserialize<AlpacaQuoteMessage>(msg.GetRawText());
                        if (quote != null)
                        {
                            _logger.LogInformation("📊 Received quote for {Symbol}", quote.Symbol);
                            await ProcessQuote(quote);
                        }
                        break;
                        
                    case "t": // Trade
                        var trade = JsonSerializer.Deserialize<AlpacaTradeMessage>(msg.GetRawText());
                        if (trade != null)
                        {
                            _logger.LogInformation("💹 Received trade for {Symbol}", trade.Symbol);
                            await ProcessTrade(trade);
                        }
                        break;
                        
                    case "subscription":
                        _logger.LogInformation("📝 Subscription update received: {Message}", msg.GetRawText());
                        break;
                        
                    default:
                        _logger.LogWarning("⚠️ Unknown message type: {Type}, Message: {Message}", type, msg.GetRawText());
                        break;
                }
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "❌ Error processing message: {Message}", message?.Length > 200 ? message.Substring(0, 200) + "..." : message);
        }
    }

    private async Task ProcessQuote(AlpacaQuoteMessage alpacaQuote)
    {
        _logger.LogInformation("📊 Processing quote for {Symbol}: Bid=${BidPrice}x{BidSize}, Ask=${AskPrice}x{AskSize}, Time={Timestamp}", 
            alpacaQuote.Symbol, alpacaQuote.BidPrice, alpacaQuote.BidSize, alpacaQuote.AskPrice, alpacaQuote.AskSize, alpacaQuote.Timestamp);
        
        // Get or create quote for this symbol
        var quote = _latestQuotes.AddOrUpdate(alpacaQuote.Symbol,
            _ => new Quote
            {
                Symbol = alpacaQuote.Symbol,
                BidPrice = alpacaQuote.BidPrice,
                AskPrice = alpacaQuote.AskPrice,
                BidSize = alpacaQuote.BidSize,
                AskSize = alpacaQuote.AskSize,
                Timestamp = alpacaQuote.Timestamp,
                Price = (alpacaQuote.BidPrice + alpacaQuote.AskPrice) / 2 // Mid price
            },
            (_, existing) => existing with
            {
                BidPrice = alpacaQuote.BidPrice,
                AskPrice = alpacaQuote.AskPrice,
                BidSize = alpacaQuote.BidSize,
                AskSize = alpacaQuote.AskSize,
                Timestamp = alpacaQuote.Timestamp,
                Price = (alpacaQuote.BidPrice + alpacaQuote.AskPrice) / 2
            });
        
        _logger.LogInformation("💾 Cached quote for {Symbol} with mid price: ${Price}", alpacaQuote.Symbol, quote.Price);
        
        // Send to subscribed connections
        if (_subscriptions.TryGetValue(alpacaQuote.Symbol, out var connectionIds))
        {
            _logger.LogInformation("📡 Broadcasting quote for {Symbol} to {Count} connection(s): [{ConnectionIds}]", 
                alpacaQuote.Symbol, connectionIds.Count, string.Join(", ", connectionIds));
            
            try
            {
                await _hubContext.Clients.Clients(connectionIds).SendAsync("QuoteUpdate", quote);
                _logger.LogInformation("✅ Successfully broadcast quote for {Symbol} to all connections", alpacaQuote.Symbol);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ Failed to broadcast quote for {Symbol}", alpacaQuote.Symbol);
            }
        }
        else
        {
            _logger.LogWarning("⚠️ No subscriptions found for symbol {Symbol} - quote will be cached but not sent", alpacaQuote.Symbol);
            _logger.LogInformation("📋 Current subscriptions: {Symbols}", string.Join(", ", _subscriptions.Keys));
        }
    }

    private async Task ProcessTrade(AlpacaTradeMessage alpacaTrade)
    {
        _logger.LogInformation("Processing trade for {Symbol}: Price={Price}, Size={Size}", 
            alpacaTrade.Symbol, alpacaTrade.Price, alpacaTrade.Size);
        
        // Update the latest quote with trade price
        var quote = _latestQuotes.AddOrUpdate(alpacaTrade.Symbol,
            _ => new Quote
            {
                Symbol = alpacaTrade.Symbol,
                Price = alpacaTrade.Price,
                Volume = alpacaTrade.Size,
                Timestamp = alpacaTrade.Timestamp
            },
            (_, existing) => existing with
            {
                Price = alpacaTrade.Price,
                Volume = existing.Volume + alpacaTrade.Size,
                Timestamp = alpacaTrade.Timestamp
            });
        
        // Send to subscribed connections
        if (_subscriptions.TryGetValue(alpacaTrade.Symbol, out var connectionIds))
        {
            _logger.LogInformation("Broadcasting trade for {Symbol} to {Count} connections: {ConnectionIds}", 
                alpacaTrade.Symbol, connectionIds.Count, string.Join(", ", connectionIds));
            await _hubContext.Clients.Clients(connectionIds).SendAsync("TradeUpdate", quote);
        }
        else
        {
            _logger.LogWarning("No subscriptions found for symbol {Symbol}", alpacaTrade.Symbol);
        }
    }

    public async Task SubscribeAsync(string symbol, string connectionId)
    {
        _logger.LogInformation("🔔 SubscribeAsync called: ConnectionId={ConnectionId}, Symbol={Symbol}", connectionId, symbol);
        _logger.LogInformation("📊 Current subscriptions before: {Count} symbols tracked", _subscriptions.Count);
        
        // Add to subscription tracking
        var isNewSymbol = false;
        var currentConnectionCount = 0;
        
        _subscriptions.AddOrUpdate(symbol,
            _ =>
            {
                isNewSymbol = true;
                _logger.LogInformation("🆕 First subscription for symbol {Symbol}", symbol);
                return new HashSet<string> { connectionId };
            },
            (_, connections) =>
            {
                connections.Add(connectionId);
                currentConnectionCount = connections.Count;
                _logger.LogInformation("➕ Adding connection to existing symbol {Symbol}. Total connections: {Count}", 
                    symbol, connections.Count);
                return connections;
            });
        
        // Track connection's subscriptions
        _connectionSubscriptions.AddOrUpdate(connectionId,
            _ => new HashSet<string> { symbol },
            (_, symbols) =>
            {
                symbols.Add(symbol);
                return symbols;
            });
        
        _logger.LogInformation("📈 Connection {ConnectionId} now subscribed to {Count} symbols", 
            connectionId, _connectionSubscriptions[connectionId].Count);
        
        // If this is a new symbol subscription, subscribe via WebSocket
        if (isNewSymbol && IsConnected)
        {
            _logger.LogInformation("🌐 New symbol {Symbol} - subscribing via Alpaca WebSocket", symbol);
            var subMessage = new AlpacaSubscriptionMessage
            {
                Action = "subscribe",
                Quotes = new List<string> { symbol },
                Trades = new List<string> { symbol }
            };
            
            await SendMessageAsync(subMessage);
        }
        else if (isNewSymbol && !IsConnected)
        {
            _logger.LogWarning("⚠️ Cannot subscribe to {Symbol} - WebSocket not connected!", symbol);
        }
        else
        {
            _logger.LogInformation("♻️ Symbol {Symbol} already subscribed - no need to resubscribe to Alpaca", symbol);
        }
        
        // Send latest quote if available from cache or fetch from REST API
        if (_latestQuotes.TryGetValue(symbol, out var quote))
        {
            _logger.LogInformation("📤 Sending cached quote for {Symbol} to {ConnectionId}", symbol, connectionId);
            await _hubContext.Clients.Client(connectionId).SendAsync("QuoteUpdate", quote);
        }
        else
        {
            _logger.LogInformation("📭 No cached quote available for {Symbol}, fetching from REST API...", symbol);
            
            // Fetch historical data from REST API
            await FetchAndSendHistoricalData(symbol, connectionId);
        }
    }

    public async Task UnsubscribeAsync(string symbol, string connectionId)
    {
        _logger.LogInformation("Unsubscribing {ConnectionId} from {Symbol}", connectionId, symbol);
        
        var shouldUnsubscribe = false;
        
        // Remove from symbol subscriptions
        if (_subscriptions.TryGetValue(symbol, out var connections))
        {
            connections.Remove(connectionId);
            if (connections.Count == 0)
            {
                _subscriptions.TryRemove(symbol, out _);
                shouldUnsubscribe = true;
            }
        }
        
        // Remove from connection subscriptions
        if (_connectionSubscriptions.TryGetValue(connectionId, out var symbols))
        {
            symbols.Remove(symbol);
            if (symbols.Count == 0)
            {
                _connectionSubscriptions.TryRemove(connectionId, out _);
            }
        }
        
        // If no more subscribers for this symbol, unsubscribe via WebSocket
        if (shouldUnsubscribe && IsConnected)
        {
            var unsubMessage = new
            {
                action = "unsubscribe",
                quotes = new[] { symbol },
                trades = new[] { symbol }
            };
            
            await SendMessageAsync(unsubMessage);
        }
    }

    public async Task UnsubscribeAllAsync(string connectionId)
    {
        _logger.LogInformation("Unsubscribing all for {ConnectionId}", connectionId);
        
        if (_connectionSubscriptions.TryRemove(connectionId, out var symbols))
        {
            foreach (var symbol in symbols)
            {
                await UnsubscribeAsync(symbol, connectionId);
            }
        }
    }

    private async Task SendMessageAsync<T>(T message)
    {
        if (_webSocket?.State != WebSocketState.Open)
        {
            _logger.LogWarning("⚠️ Cannot send message, WebSocket state is: {State}", _webSocket?.State.ToString() ?? "null");
            return;
        }
        
        var json = JsonSerializer.Serialize(message);
        _logger.LogInformation("📤 Sending message to Alpaca WebSocket: {Message}", json);
        var bytes = Encoding.UTF8.GetBytes(json);
        
        try
        {
            await _webSocket.SendAsync(new ArraySegment<byte>(bytes), WebSocketMessageType.Text, true, CancellationToken.None);
            _logger.LogInformation("✅ Message sent successfully to Alpaca");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "❌ Failed to send message to Alpaca WebSocket");
            throw;
        }
    }

    private async Task HandleDisconnection()
    {
        _logger.LogWarning("WebSocket disconnected, attempting to reconnect");
        
        _webSocket?.Dispose();
        _webSocket = null;
        
        // Notify all clients of disconnection
        await _hubContext.Clients.All.SendAsync("MarketDataDisconnected");
        
        // Attempt to reconnect
        await Task.Delay(5000);
        await ConnectAsync();
        
        // Resubscribe to all symbols
        if (IsConnected)
        {
            var symbols = _subscriptions.Keys.ToList();
            if (symbols.Any())
            {
                var subMessage = new AlpacaSubscriptionMessage
                {
                    Action = "subscribe",
                    Quotes = symbols,
                    Trades = symbols
                };
                
                await SendMessageAsync(subMessage);
            }
            
            await _hubContext.Clients.All.SendAsync("MarketDataConnected");
        }
    }
    
    private bool IsMarketHours()
    {
        var now = DateTime.Now;
        var easternTime = TimeZoneInfo.ConvertTime(now, TimeZoneInfo.FindSystemTimeZoneById("Eastern Standard Time"));
        
        // Check if it's a weekday (market only operates Mon-Fri)
        if (easternTime.DayOfWeek < DayOfWeek.Monday || easternTime.DayOfWeek > DayOfWeek.Friday)
            return false;
            
        // Market hours: 9:30 AM - 4:00 PM EST
        var marketOpen = new TimeSpan(9, 30, 0);
        var marketClose = new TimeSpan(16, 0, 0);
        
        return easternTime.TimeOfDay >= marketOpen && easternTime.TimeOfDay < marketClose;
    }
    
    private bool IsExtendedHours()
    {
        var now = DateTime.Now;
        var easternTime = TimeZoneInfo.ConvertTime(now, TimeZoneInfo.FindSystemTimeZoneById("Eastern Standard Time"));
        
        // Check if it's a weekday
        if (easternTime.DayOfWeek < DayOfWeek.Monday || easternTime.DayOfWeek > DayOfWeek.Friday)
            return false;
            
        // Extended hours: 4:00 AM - 8:00 PM EST
        var extendedStart = new TimeSpan(4, 0, 0);
        var extendedEnd = new TimeSpan(20, 0, 0);
        var marketOpen = new TimeSpan(9, 30, 0);
        var marketClose = new TimeSpan(16, 0, 0);
        
        var currentTime = easternTime.TimeOfDay;
        
        // Pre-market: 4:00 AM - 9:30 AM or After-hours: 4:00 PM - 8:00 PM
        return (currentTime >= extendedStart && currentTime < marketOpen) || 
               (currentTime >= marketClose && currentTime < extendedEnd);
    }
    
    private async Task<bool> TryFetchYahooData(string symbol, string connectionId)
    {
        try
        {
            _logger.LogInformation("🎯 Attempting to fetch Yahoo Finance data for {Symbol}", symbol);
            
            var yahooQuote = await _yahooFinanceClient.GetLatestQuoteAsync(symbol);
            if (yahooQuote?.Quote == null)
            {
                _logger.LogWarning("❌ No Yahoo Finance data available for {Symbol}", symbol);
                return false;
            }
            
            var yahoo = yahooQuote.Quote;
            
            // Use post-market data if available and we're in after-hours
            var currentPrice = yahoo.PostMarketPrice ?? yahoo.PreMarketPrice ?? yahoo.RegularMarketPrice;
            var change = yahoo.PostMarketChange ?? yahoo.PreMarketChange ?? (yahoo.RegularMarketPrice - yahoo.RegularMarketPreviousClose);
            var changePercent = yahoo.PostMarketChangePercent ?? yahoo.PreMarketChangePercent ?? 
                               (yahoo.RegularMarketPreviousClose > 0 ? (change / yahoo.RegularMarketPreviousClose) * 100 : 0);
            
            // Create quote from Yahoo data
            var quote = new Quote
            {
                Symbol = symbol,
                Price = currentPrice,
                BidPrice = currentPrice, // Yahoo doesn't provide bid/ask in basic API
                AskPrice = currentPrice,
                BidSize = 0,
                AskSize = 0,
                Volume = yahoo.RegularMarketVolume,
                Timestamp = yahoo.PostMarketTime ?? yahoo.PreMarketTime ?? yahoo.RegularMarketTime,
                DayHigh = yahoo.RegularMarketDayHigh,
                DayLow = yahoo.RegularMarketDayLow,
                PreviousClose = yahoo.RegularMarketPreviousClose,
                Change = change,
                ChangePercent = changePercent,
                DataSource = IsExtendedHours() ? $"Yahoo Finance ({yahoo.MarketState})" : "Yahoo Finance"
            };
            
            // Cache the quote
            _latestQuotes[symbol] = quote;
            
            // Send to the requesting connection
            _logger.LogInformation("📤 Sending Yahoo Finance quote for {Symbol} to {ConnectionId}: Price=${Price}, Source={DataSource}", 
                symbol, connectionId, quote.Price, quote.DataSource);
            await _hubContext.Clients.Client(connectionId).SendAsync("QuoteUpdate", quote);
            
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "❌ Error fetching Yahoo Finance data for {Symbol}", symbol);
            return false;
        }
    }

    private async Task FetchAndSendHistoricalData(string symbol, string connectionId)
    {
        try
        {
            _logger.LogInformation("🔍 Fetching historical data for {Symbol}", symbol);
            
            bool isRegularMarketHours = IsMarketHours();
            bool isExtendedHours = IsExtendedHours();
            
            _logger.LogInformation("📅 Market status - Regular hours: {IsRegularHours}, Extended hours: {IsExtendedHours}", 
                isRegularMarketHours, isExtendedHours);
            
            // During after-hours or weekends, prioritize Yahoo Finance for more recent data
            if (!isRegularMarketHours)
            {
                _logger.LogInformation("🎯 Using Yahoo Finance for after-hours/weekend data for {Symbol}", symbol);
                var yahooSuccess = await TryFetchYahooData(symbol, connectionId);
                if (yahooSuccess) return;
                
                _logger.LogWarning("⚠️ Yahoo Finance failed, falling back to Alpaca REST API for {Symbol}", symbol);
            }
            
            // Try to get the latest quote first from Alpaca
            var quoteResponse = await _marketDataRestClient.GetLatestQuoteAsync(symbol);
            
            if (quoteResponse?.Quote != null)
            {
                var alpacaQuote = quoteResponse.Quote;
                var quote = new Quote
                {
                    Symbol = symbol,
                    BidPrice = alpacaQuote.BidPrice,
                    AskPrice = alpacaQuote.AskPrice,
                    BidSize = (decimal)alpacaQuote.BidSize,
                    AskSize = (decimal)alpacaQuote.AskSize,
                    Price = (alpacaQuote.BidPrice + alpacaQuote.AskPrice) / 2,
                    Timestamp = alpacaQuote.Timestamp,
                    Volume = 0, // Will be updated from bar data
                    Change = 0,
                    ChangePercent = 0,
                    DayHigh = 0,
                    DayLow = 0,
                    PreviousClose = 0
                };
                
                // Try to get bar data for additional information
                var barsResponse = await _marketDataRestClient.GetBarsAsync(symbol, "1Day", 2);
                if (barsResponse?.Bars?.Count >= 1)
                {
                    var todayBar = barsResponse.Bars.Last();
                    quote = quote with
                    {
                        Volume = todayBar.Volume,
                        DayHigh = todayBar.High,
                        DayLow = todayBar.Low
                    };
                    
                    // Calculate change if we have previous day's data
                    if (barsResponse.Bars.Count >= 2)
                    {
                        var previousBar = barsResponse.Bars[barsResponse.Bars.Count - 2];
                        quote = quote with
                        {
                            PreviousClose = previousBar.Close,
                            Change = quote.Price - previousBar.Close,
                            ChangePercent = previousBar.Close > 0 ? ((quote.Price - previousBar.Close) / previousBar.Close) * 100 : 0
                        };
                    }
                }
                
                // Cache the quote
                _latestQuotes[symbol] = quote;
                
                // Send to the requesting connection
                _logger.LogInformation("📤 Sending historical quote for {Symbol} to {ConnectionId}: Price=${Price}, Change={Change}%", 
                    symbol, connectionId, quote.Price, quote.ChangePercent.ToString("F2"));
                await _hubContext.Clients.Client(connectionId).SendAsync("QuoteUpdate", quote);
            }
            else
            {
                _logger.LogWarning("❌ No historical quote data available for {Symbol}", symbol);
                
                // Try to get at least bar data
                var barsResponse = await _marketDataRestClient.GetBarsAsync(symbol, "1Day", 2);
                if (barsResponse?.Bars?.Count >= 1)
                {
                    var latestBar = barsResponse.Bars.Last();
                    var quote = new Quote
                    {
                        Symbol = symbol,
                        Price = latestBar.Close,
                        BidPrice = latestBar.Close,
                        AskPrice = latestBar.Close,
                        BidSize = 0,
                        AskSize = 0,
                        Volume = latestBar.Volume,
                        Timestamp = latestBar.Timestamp,
                        DayHigh = latestBar.High,
                        DayLow = latestBar.Low,
                        Change = 0,
                        ChangePercent = 0,
                        PreviousClose = 0
                    };
                    
                    if (barsResponse.Bars.Count >= 2)
                    {
                        var previousBar = barsResponse.Bars[barsResponse.Bars.Count - 2];
                        quote = quote with
                        {
                            PreviousClose = previousBar.Close,
                            Change = latestBar.Close - previousBar.Close,
                            ChangePercent = previousBar.Close > 0 ? ((latestBar.Close - previousBar.Close) / previousBar.Close) * 100 : 0
                        };
                    }
                    
                    // Cache and send
                    _latestQuotes[symbol] = quote;
                    _logger.LogInformation("📤 Sending bar-based quote for {Symbol} to {ConnectionId}: Close=${Price}", 
                        symbol, connectionId, quote.Price);
                    await _hubContext.Clients.Client(connectionId).SendAsync("QuoteUpdate", quote);
                }
                else
                {
                    _logger.LogError("❌ No historical data available for {Symbol} from REST API", symbol);
                }
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "❌ Failed to fetch historical data for {Symbol}", symbol);
        }
    }
}