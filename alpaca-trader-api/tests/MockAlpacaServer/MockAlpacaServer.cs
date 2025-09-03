using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using System.Text;
using System.Text.Json;

var builder = WebApplication.CreateBuilder(args);

// Configure to listen on port 5001
builder.WebHost.UseUrls("http://localhost:5001");

var app = builder.Build();

// Mock responses as strings to simulate Broker API behavior
var mockAccountResponse = @"{
    ""account_number"": ""920964623"",
    ""status"": ""ACTIVE"",
    ""currency"": ""USD"",
    ""cash"": ""24190.64"",
    ""portfolio_value"": ""24190.64"",
    ""pattern_day_trader"": false,
    ""trading_blocked"": false,
    ""transfers_blocked"": false,
    ""account_blocked"": false,
    ""buying_power"": ""24190.64"",
    ""regt_buying_power"": ""24190.64"",
    ""daytrading_buying_power"": ""0"",
    ""non_marginable_buying_power"": ""24190.64"",
    ""accrued_fees"": ""0"",
    ""pending_transfer_in"": ""0"",
    ""pending_transfer_out"": ""0"",
    ""crypto_status"": ""INACTIVE"",
    ""created_at"": ""2024-10-15T18:45:51.894941Z"",
    ""trade_suspended_by_user"": false,
    ""multiplier"": ""1"",
    ""shorting_enabled"": true,
    ""equity"": ""24190.64"",
    ""last_equity"": ""24190.64"",
    ""long_market_value"": ""0"",
    ""short_market_value"": ""0"",
    ""initial_margin"": ""0"",
    ""maintenance_margin"": ""0"",
    ""daytrade_count"": 0,
    ""sma"": ""0""
}";

var mockPositionsResponse = @"[]";
var mockOrdersResponse = @"[]";

// Middleware to check authentication
app.Use(async (context, next) =>
{
    // Skip auth for health check
    if (context.Request.Path == "/health")
    {
        await next();
        return;
    }
    
    var authHeader = context.Request.Headers["Authorization"].ToString();
    
    if (string.IsNullOrEmpty(authHeader))
    {
        context.Response.StatusCode = 401;
        await context.Response.WriteAsync("Unauthorized");
        return;
    }
    
    if (!authHeader.StartsWith("Basic "))
    {
        context.Response.StatusCode = 401;
        await context.Response.WriteAsync("Invalid auth format");
        return;
    }
    
    // Decode basic auth
    var encodedCreds = authHeader.Substring("Basic ".Length).Trim();
    var decodedCreds = Encoding.UTF8.GetString(Convert.FromBase64String(encodedCreds));
    var parts = decodedCreds.Split(':');
    
    if (parts.Length != 2 || parts[0] != "CKB4051UELTQZSUS78S8" || parts[1] != "ZdjZPMzxPcAf7aWngyC1UtHJfHdRjvssxIvCJTlA")
    {
        context.Response.StatusCode = 403;
        await context.Response.WriteAsync("Forbidden");
        return;
    }
    
    await next();
});

// Broker API endpoints
app.MapGet("/v1/trading/accounts/{accountId}/account", (string accountId) =>
{
    if (accountId != "920964623")
    {
        return Results.NotFound("Not found");
    }
    
    return Results.Content(mockAccountResponse, "application/json");
});

app.MapGet("/v1/trading/accounts/{accountId}/positions", (string accountId) =>
{
    return Results.Content(mockPositionsResponse, "application/json");
});

app.MapGet("/v1/trading/accounts/{accountId}/orders", (string accountId) =>
{
    return Results.Content(mockOrdersResponse, "application/json");
});

app.MapGet("/v1/accounts", () =>
{
    var accounts = @"[{
        ""id"": ""920964623"",
        ""account_number"": ""920964623"",
        ""status"": ""ACTIVE"",
        ""currency"": ""USD"",
        ""last_equity"": ""24190.64"",
        ""created_at"": ""2024-10-15T18:45:51.894941Z""
    }]";
    
    return Results.Content(accounts, "application/json");
});

// Trading API endpoints (for fallback)
app.MapGet("/v2/account", () =>
{
    return Results.Content(mockAccountResponse, "application/json");
});

app.MapGet("/v2/positions", () =>
{
    return Results.Content(mockPositionsResponse, "application/json");
});

app.MapGet("/v2/orders", () =>
{
    return Results.Content(mockOrdersResponse, "application/json");
});

// Health check endpoint (no auth required)
app.MapGet("/health", () => Results.Ok(new { status = "healthy", service = "MockAlpacaServer" }))
    .AllowAnonymous();

app.Run();