using Serilog;
using System.Text.Json;
using TraderApi.Extensions;
using TraderApi.Observability;
using TraderApi.Features.Auth.Extensions;
using TraderApi.Features.Auth;
using TraderApi.Features.Kyc;
using TraderApi.Features.Funding;
using TraderApi.Features.Layouts;
using TraderApi.Features.MarketData;
using TraderApi.Middleware;
using DotNetEnv;

// Load environment variables from .env file
var currentDir = Directory.GetCurrentDirectory();
var envPath = Path.Combine(currentDir, ".env");
if (!File.Exists(envPath))
{
    // Try parent directories
    envPath = Path.Combine(currentDir, "..", "..", ".env");
}

if (File.Exists(envPath))
{
    Console.WriteLine($"Loading .env file from: {envPath}");
    Env.Load(envPath);
}
else
{
    Console.WriteLine($".env file not found at: {envPath}");
}

var builder = WebApplication.CreateBuilder(args);

// Add environment variables to configuration
builder.Configuration.AddEnvironmentVariables();

// Configure Serilog
Logging.ConfigureSerilog(builder);

// Add services
builder.Services.AddApplicationServices(builder.Configuration);

// Add custom authentication instead of Auth0
builder.Services.AddCustomAuthentication(builder.Configuration);

builder.Services.AddRateLimiting(builder.Configuration);
builder.Services.AddSwagger();

// Configure JSON options to use camelCase
builder.Services.ConfigureHttpJsonOptions(options =>
{
    options.SerializerOptions.PropertyNameCaseInsensitive = true;
    options.SerializerOptions.PropertyNamingPolicy = JsonNamingPolicy.CamelCase; // Use camelCase for JSON properties
});

// Configure CORS with authentication and WebSocket support
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFrontend", policy =>
    {
        var allowedOrigins = builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>() 
            ?? new[] { "http://localhost:3000", "ws://localhost:3000" };
            
        policy
            .WithOrigins(allowedOrigins)
            .AllowAnyMethod()
            .AllowAnyHeader()
            .AllowCredentials()
            .WithExposedHeaders("Token-Expired");
    });
});

// Add request logging
builder.Services.AddHttpLogging(options =>
{
    options.LoggingFields = Microsoft.AspNetCore.HttpLogging.HttpLoggingFields.RequestPath |
                          Microsoft.AspNetCore.HttpLogging.HttpLoggingFields.RequestMethod |
                          Microsoft.AspNetCore.HttpLogging.HttpLoggingFields.ResponseStatusCode;
});

var app = builder.Build();

// Configure pipeline
app.UseExceptionHandling();
app.UseSerilogRequestLogging();
app.UseHttpLogging();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors("AllowFrontend");

// WebSockets middleware must be added before routing
app.UseWebSockets();

app.UseAuthentication();
app.UseAuthorization();
app.UseKycRequired(); // Add KYC requirement middleware
// Disable rate limiting in development for debugging
if (!app.Environment.IsDevelopment())
{
    app.UseRateLimiter();
}

// Map endpoints
app.MapEndpoints();

// Map auth endpoints
app.MapAuthEndpoints();

// Map KYC endpoints
app.MapKycEndpoints();

// Map funding endpoints
app.MapFundingEndpoints();

// Map layout endpoints
app.MapLayoutsEndpoints();

// Map market data endpoints
app.MapMarketDataEndpoints();

// Apply migrations on startup (development only)
if (app.Environment.IsDevelopment())
{
    try
    {
        using var scope = app.Services.CreateScope();
        
        // Ensure main database
        var db = scope.ServiceProvider.GetRequiredService<TraderApi.Data.AppDbContext>();
        await db.Database.EnsureCreatedAsync();
        
        // Initialize auth database
        await app.InitializeAuthDatabaseAsync();
    }
    catch (Exception ex)
    {
        app.Logger.LogWarning(ex, "Could not create database. Running without database.");
    }
}

app.Run();