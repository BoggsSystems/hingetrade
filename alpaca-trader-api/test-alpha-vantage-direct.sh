#!/bin/bash

echo "🧪 Testing Alpha Vantage integration directly..."

# Create a simple test endpoint without authentication
echo "Creating temporary test endpoint..."

cat > temp-test-endpoint.cs << 'EOF'
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
EOF

echo "📝 Test endpoint code created in temp-test-endpoint.cs"
echo ""
echo "To add this to Program.cs, add the content after the MapSymbolsEndpoints call."
echo ""
echo "For now, let's test what the current frontend is actually sending..."

echo ""
echo "🔍 Let's check what token the frontend is using..."
echo "Look in your browser's Network tab -> Request Headers -> Authorization header"
echo "Copy the Bearer token and run:"
echo "curl -H \"Authorization: Bearer YOUR_TOKEN_HERE\" \"http://localhost:5001/api/symbols/search?query=AAPL\""