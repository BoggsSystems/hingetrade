using Microsoft.EntityFrameworkCore;
using TraderApi.Alpaca;
using TraderApi.Alpaca.Models;
using TraderApi.Data;
using TraderApi.Data.Entities;

namespace TraderApi.Features.Assets;

public interface IAssetValidationService
{
    Task<bool> IsAssetTradableAsync(string symbol);
    Task<AlpacaAsset?> GetAssetInfoAsync(string symbol);
    Task<List<AlpacaAsset>> GetAllTradableAssetsAsync();
    Task RefreshAssetCacheAsync();
    Task<List<AssetSearchResult>> SearchAssetsAsync(string query, int limit = 20);
}

public class AssetValidationService : IAssetValidationService
{
    private readonly IAlpacaClient _alpacaClient;
    private readonly AppDbContext _db;
    private readonly ILogger<AssetValidationService> _logger;
    private static readonly TimeSpan CacheExpiration = TimeSpan.FromHours(24);

    public AssetValidationService(
        IAlpacaClient alpacaClient,
        AppDbContext db,
        ILogger<AssetValidationService> logger)
    {
        _alpacaClient = alpacaClient;
        _db = db;
        _logger = logger;
    }

    public async Task<bool> IsAssetTradableAsync(string symbol)
    {
        var asset = await GetAssetInfoAsync(symbol);
        return asset?.Tradable ?? false;
    }

    public async Task<AlpacaAsset?> GetAssetInfoAsync(string symbol)
    {
        // First check cache
        var cached = await _db.AssetCache
            .Where(a => a.Symbol == symbol.ToUpper())
            .FirstOrDefaultAsync();
            
        if (cached != null && cached.LastUpdated > DateTime.UtcNow.Subtract(CacheExpiration))
        {
            return MapCacheToAsset(cached);
        }

        // Fetch from Alpaca API
        try
        {
            var asset = await _alpacaClient.GetAssetAsync(symbol);
            if (asset != null)
            {
                await UpdateCacheAsync(asset);
            }
            return asset;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching asset {Symbol}", symbol);
            return cached != null ? MapCacheToAsset(cached) : null;
        }
    }

    public async Task<List<AlpacaAsset>> GetAllTradableAssetsAsync()
    {
        // Check if cache is fresh
        var cacheCount = await _db.AssetCache.CountAsync();
        var oldestCache = await _db.AssetCache
            .OrderBy(a => a.LastUpdated)
            .FirstOrDefaultAsync();
            
        if (cacheCount > 1000 && oldestCache?.LastUpdated > DateTime.UtcNow.Subtract(CacheExpiration))
        {
            // Use cache
            var cached = await _db.AssetCache
                .Where(a => a.Tradable)
                .Select(a => MapCacheToAsset(a))
                .ToListAsync();
            return cached;
        }

        // Refresh from API
        await RefreshAssetCacheAsync();
        
        return await _db.AssetCache
            .Where(a => a.Tradable)
            .Select(a => MapCacheToAsset(a))
            .ToListAsync();
    }

    public async Task RefreshAssetCacheAsync()
    {
        _logger.LogInformation("Refreshing asset cache");
        
        try
        {
            var assets = await _alpacaClient.GetAssetsAsync(status: "active");
            
            foreach (var asset in assets)
            {
                await UpdateCacheAsync(asset);
            }
            
            await _db.SaveChangesAsync();
            
            _logger.LogInformation("Asset cache refreshed with {Count} assets", assets.Count);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error refreshing asset cache");
        }
    }

    public async Task<List<AssetSearchResult>> SearchAssetsAsync(string query, int limit = 20)
    {
        query = query.ToUpper();
        
        var results = await _db.AssetCache
            .Where(a => a.Tradable && 
                       (a.Symbol.StartsWith(query) || 
                        a.Name.ToUpper().Contains(query)))
            .OrderBy(a => a.Symbol.StartsWith(query) ? 0 : 1)
            .ThenBy(a => a.Symbol)
            .Take(limit)
            .Select(a => new AssetSearchResult
            {
                Symbol = a.Symbol,
                Name = a.Name,
                Exchange = a.Exchange,
                AssetClass = a.AssetClass,
                Tradable = a.Tradable,
                Fractionable = a.Fractionable
            })
            .ToListAsync();
            
        return results;
    }

    private async Task UpdateCacheAsync(AlpacaAsset asset)
    {
        var cached = await _db.AssetCache
            .FirstOrDefaultAsync(a => a.Symbol == asset.Symbol);
            
        if (cached == null)
        {
            cached = new AssetCache
            {
                Symbol = asset.Symbol
            };
            _db.AssetCache.Add(cached);
        }
        
        cached.Name = asset.Name;
        cached.Exchange = asset.Exchange;
        cached.AssetClass = asset.Class;
        cached.Tradable = asset.Tradable;
        cached.Marginable = asset.Marginable;
        cached.Shortable = asset.Shortable;
        cached.EasyToBorrow = asset.EasyToBorrow;
        cached.Fractionable = asset.Fractionable;
        cached.MinOrderSize = asset.MinOrderSize;
        cached.MinTradeIncrement = asset.MinTradeIncrement;
        cached.PriceIncrement = asset.PriceIncrement;
        cached.LastUpdated = DateTime.UtcNow;
    }

    private static AlpacaAsset MapCacheToAsset(AssetCache cache)
    {
        return new AlpacaAsset
        {
            Symbol = cache.Symbol,
            Name = cache.Name,
            Exchange = cache.Exchange,
            Class = cache.AssetClass,
            Status = cache.Tradable ? "active" : "inactive",
            Tradable = cache.Tradable,
            Marginable = cache.Marginable,
            Shortable = cache.Shortable,
            EasyToBorrow = cache.EasyToBorrow,
            Fractionable = cache.Fractionable,
            MinOrderSize = cache.MinOrderSize,
            MinTradeIncrement = cache.MinTradeIncrement,
            PriceIncrement = cache.PriceIncrement
        };
    }
}