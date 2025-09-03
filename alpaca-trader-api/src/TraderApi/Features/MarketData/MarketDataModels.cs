using System.Text.Json.Serialization;

namespace TraderApi.Features.MarketData;

public record Quote
{
    public required string Symbol { get; init; }
    public decimal Price { get; init; }
    public decimal BidPrice { get; init; }
    public decimal AskPrice { get; init; }
    public decimal BidSize { get; init; }
    public decimal AskSize { get; init; }
    public long Volume { get; init; }
    public DateTime Timestamp { get; init; }
    
    // Calculated fields
    public decimal Change { get; init; }
    public decimal ChangePercent { get; init; }
    public decimal DayHigh { get; init; }
    public decimal DayLow { get; init; }
    public decimal PreviousClose { get; init; }
    public string DataSource { get; init; } = "Alpaca";
}

// Alpaca WebSocket message types
public record AlpacaStreamMessage
{
    [JsonPropertyName("T")]
    public string? Type { get; init; }
    
    [JsonPropertyName("msg")]
    public string? Message { get; init; }
    
    [JsonPropertyName("code")]
    public int? Code { get; init; }
}

public record AlpacaQuoteMessage : AlpacaStreamMessage
{
    [JsonPropertyName("S")]
    public string Symbol { get; init; } = string.Empty;
    
    [JsonPropertyName("bp")]
    public decimal BidPrice { get; init; }
    
    [JsonPropertyName("ap")]
    public decimal AskPrice { get; init; }
    
    [JsonPropertyName("bs")]
    public decimal BidSize { get; init; }
    
    [JsonPropertyName("as")]
    public decimal AskSize { get; init; }
    
    [JsonPropertyName("t")]
    public DateTime Timestamp { get; init; }
}

public record AlpacaTradeMessage : AlpacaStreamMessage
{
    [JsonPropertyName("S")]
    public string Symbol { get; init; } = string.Empty;
    
    [JsonPropertyName("p")]
    public decimal Price { get; init; }
    
    [JsonPropertyName("s")]
    public long Size { get; init; }
    
    [JsonPropertyName("t")]
    public DateTime Timestamp { get; init; }
}

public record AlpacaAuthMessage : AlpacaStreamMessage
{
    [JsonPropertyName("action")]
    public string Action { get; init; } = "auth";
    
    [JsonPropertyName("key")]
    public string? Key { get; init; }
    
    [JsonPropertyName("secret")]
    public string? Secret { get; init; }
}

public record AlpacaSubscriptionMessage
{
    [JsonPropertyName("action")]
    public string Action { get; init; } = "subscribe";
    
    [JsonPropertyName("trades")]
    public List<string>? Trades { get; init; }
    
    [JsonPropertyName("quotes")]
    public List<string>? Quotes { get; init; }
}