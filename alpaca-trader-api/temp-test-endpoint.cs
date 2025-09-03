// Temporary test endpoint to bypass auth and test Alpha Vantage directly
app.MapGet("/api/test/symbols", async (
    string? query,
    AlphaVantageClient alphaVantageClient,
    CancellationToken cancellationToken,
    ILogger<object> logger) =>
{
    logger.LogInformation("🧪 [TEST] Testing Alpha Vantage with query: '{Query}'", query ?? "NULL");
    
    if (string.IsNullOrWhiteSpace(query) || query.Length < 2)
    {
        logger.LogInformation("🧪 [TEST] Query too short, returning empty result");
        return Results.Ok(new { symbols = new List<object>() });
    }

    logger.LogInformation("🧪 [TEST] Calling AlphaVantageClient.SearchSymbolsAsync");
    var searchResult = await alphaVantageClient.SearchSymbolsAsync(query, cancellationToken);
    
    logger.LogInformation("🧪 [TEST] Got result: {Result}", searchResult != null ? $"{searchResult.BestMatches?.Count ?? 0} matches" : "NULL");
    
    if (searchResult?.BestMatches != null)
    {
        var symbols = searchResult.BestMatches
            .Where(m => m.Region == "United States" && (m.Type == "Equity" || m.Type == "ETF"))
            .Select(m => new { symbol = m.Symbol, name = m.Name, type = m.Type })
            .Take(5)
            .ToList();
            
        logger.LogInformation("🧪 [TEST] Returning {Count} filtered symbols", symbols.Count);
        return Results.Ok(new { symbols });
    }
    
    logger.LogInformation("🧪 [TEST] Returning empty result");
    return Results.Ok(new { symbols = new List<object>() });
})
.WithName("TestSymbols")
.WithSummary("Test Alpha Vantage integration");
