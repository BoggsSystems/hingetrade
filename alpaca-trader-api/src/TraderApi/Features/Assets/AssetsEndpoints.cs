using Microsoft.AspNetCore.Http.HttpResults;
using TraderApi.Alpaca.Models;

namespace TraderApi.Features.Assets;

public static class AssetsEndpoints
{
    public static void MapAssetsEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/assets")
            .RequireAuthorization()
            .WithTags("Assets");

        group.MapGet("/", GetAllAssets)
            .WithName("GetAllAssets")
            .WithSummary("Get all tradable assets")
            .WithDescription("Returns cached list of tradable assets. Use refresh=true to force update.")
            .Produces<List<AlpacaAsset>>();

        group.MapGet("/search", SearchAssets)
            .WithName("SearchAssets")
            .WithSummary("Search assets by symbol or name")
            .Produces<List<AssetSearchResult>>();

        group.MapGet("/{symbol}", GetAssetDetails)
            .WithName("GetAssetDetails")
            .WithSummary("Get detailed information about an asset")
            .Produces<AlpacaAsset>()
            .Produces(404);

        group.MapPost("/refresh", RefreshAssetCache)
            .WithName("RefreshAssetCache")
            .WithSummary("Force refresh of asset cache")
            .RequireAuthorization("Admin"); // Only admins can refresh
    }

    private static async Task<Ok<List<AlpacaAsset>>> GetAllAssets(
        IAssetValidationService assetService,
        bool refresh = false)
    {
        if (refresh)
        {
            await assetService.RefreshAssetCacheAsync();
        }
        
        var assets = await assetService.GetAllTradableAssetsAsync();
        return TypedResults.Ok(assets);
    }

    private static async Task<Ok<List<AssetSearchResult>>> SearchAssets(
        IAssetValidationService assetService,
        string query,
        int limit = 20)
    {
        if (string.IsNullOrWhiteSpace(query) || query.Length < 1)
        {
            return TypedResults.Ok(new List<AssetSearchResult>());
        }
        
        var results = await assetService.SearchAssetsAsync(query, limit);
        return TypedResults.Ok(results);
    }

    private static async Task<Results<Ok<AlpacaAsset>, NotFound>> GetAssetDetails(
        IAssetValidationService assetService,
        string symbol)
    {
        var asset = await assetService.GetAssetInfoAsync(symbol.ToUpper());
        
        if (asset == null)
        {
            return TypedResults.NotFound();
        }
        
        return TypedResults.Ok(asset);
    }

    private static async Task<Ok> RefreshAssetCache(
        IAssetValidationService assetService)
    {
        await assetService.RefreshAssetCacheAsync();
        return TypedResults.Ok();
    }
}