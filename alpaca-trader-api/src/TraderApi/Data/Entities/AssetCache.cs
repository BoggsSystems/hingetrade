namespace TraderApi.Data.Entities;

public class AssetCache
{
    public string Symbol { get; set; } = default!;
    public string Name { get; set; } = default!;
    public string Exchange { get; set; } = default!;
    public string AssetClass { get; set; } = default!;
    public bool Tradable { get; set; }
    public bool Marginable { get; set; }
    public bool Shortable { get; set; }
    public bool EasyToBorrow { get; set; }
    public bool Fractionable { get; set; }
    public decimal? MinOrderSize { get; set; }
    public decimal? MinTradeIncrement { get; set; }
    public decimal? PriceIncrement { get; set; }
    public DateTime LastUpdated { get; set; }
}