using Microsoft.AspNetCore.Authorization;
using TraderApi.Features.MarketData;

namespace TraderApi.Features.Symbols;

public static class SymbolsEndpoints
{
    public static IEndpointRouteBuilder MapSymbolsEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/symbols")
            .RequireAuthorization()
            .WithTags("Symbols");

        group.MapGet("/search", SearchSymbols)
            .WithName("SearchSymbols")
            .WithSummary("Search for symbols using Alpha Vantage")
            .WithDescription("Search for stock symbols and company names using Alpha Vantage API");

        return app;
    }

    private static async Task<IResult> SearchSymbols(
        string? query,
        AlphaVantageClient alphaVantageClient,
        CancellationToken cancellationToken,
        ILogger<object> logger)
    {
        logger.LogInformation("=============== [SymbolsEndpoint] SearchSymbols called with query: '{Query}' ===============", query);
        
        if (string.IsNullOrWhiteSpace(query) || query.Length < 2)
        {
            logger.LogInformation("[SymbolsEndpoint] Query too short or empty, returning empty result");
            return Results.Ok(new SymbolSearchResultDto { Symbols = new List<SymbolDto>() });
        }

        logger.LogInformation("[SymbolsEndpoint] Calling AlphaVantageClient.SearchSymbolsAsync");
        var searchResult = await alphaVantageClient.SearchSymbolsAsync(query, cancellationToken);
        
        if (searchResult == null)
        {
            logger.LogWarning("[SymbolsEndpoint] AlphaVantageClient returned null, returning empty result");
            return Results.Ok(new SymbolSearchResultDto { Symbols = new List<SymbolDto>() });
        }

        logger.LogInformation("[SymbolsEndpoint] AlphaVantageClient returned {Count} matches", searchResult.BestMatches?.Count ?? 0);

        var allMatches = searchResult.BestMatches ?? new List<SymbolMatch>();
        logger.LogInformation("[SymbolsEndpoint] Processing {Count} matches", allMatches.Count);

        foreach (var match in allMatches.Take(5)) // Log first 5 matches for debugging
        {
            logger.LogInformation("[SymbolsEndpoint] Match: Symbol={Symbol}, Name={Name}, Type={Type}, Region={Region}", 
                match.Symbol, match.Name, match.Type, match.Region);
        }

        var symbols = allMatches
            .Where(m => m.Region == "United States" && (m.Type == "Equity" || m.Type == "ETF"))
            .Select(m => new SymbolDto
            {
                Symbol = m.Symbol,
                Name = m.Name,
                Type = MapAssetType(m.Type),
                Currency = m.Currency
            })
            .Take(10) // Limit results
            .ToList();

        logger.LogInformation("[SymbolsEndpoint] Filtered to {Count} US Equity/ETF symbols", symbols.Count);
        
        var result = new SymbolSearchResultDto { Symbols = symbols };
        logger.LogInformation("[SymbolsEndpoint] Returning result with {Count} symbols", result.Symbols.Count);

        return Results.Ok(result);
    }

    private static string MapAssetType(string alphaVantageType)
    {
        return alphaVantageType switch
        {
            "Equity" => "Stock",
            "ETF" => "ETF",
            _ => "Other"
        };
    }
}

public class SymbolSearchResultDto
{
    public List<SymbolDto> Symbols { get; set; } = new();
}

public class SymbolDto
{
    public required string Symbol { get; set; }
    public required string Name { get; set; }
    public required string Type { get; set; }
    public required string Currency { get; set; }
}