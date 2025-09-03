using System.Text.Json.Serialization;

namespace TraderApi.Alpaca.Models;

public class AlpacaAsset
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = default!;
    
    [JsonPropertyName("class")]
    public string Class { get; set; } = default!;
    
    [JsonPropertyName("exchange")]
    public string Exchange { get; set; } = default!;
    
    [JsonPropertyName("symbol")]
    public string Symbol { get; set; } = default!;
    
    [JsonPropertyName("name")]
    public string Name { get; set; } = default!;
    
    [JsonPropertyName("status")]
    public string Status { get; set; } = default!;
    
    [JsonPropertyName("tradable")]
    public bool Tradable { get; set; }
    
    [JsonPropertyName("marginable")]
    public bool Marginable { get; set; }
    
    [JsonPropertyName("shortable")]
    public bool Shortable { get; set; }
    
    [JsonPropertyName("easy_to_borrow")]
    public bool EasyToBorrow { get; set; }
    
    [JsonPropertyName("fractionable")]
    public bool Fractionable { get; set; }
    
    [JsonPropertyName("min_order_size")]
    public decimal? MinOrderSize { get; set; }
    
    [JsonPropertyName("min_trade_increment")]
    public decimal? MinTradeIncrement { get; set; }
    
    [JsonPropertyName("price_increment")]
    public decimal? PriceIncrement { get; set; }
    
    [JsonPropertyName("maintenance_margin_requirement")]
    public decimal? MaintenanceMarginRequirement { get; set; }
}

public class AssetSearchResult
{
    public string Symbol { get; set; } = default!;
    public string Name { get; set; } = default!;
    public string Exchange { get; set; } = default!;
    public string AssetClass { get; set; } = default!;
    public bool Tradable { get; set; }
    public bool Fractionable { get; set; }
}