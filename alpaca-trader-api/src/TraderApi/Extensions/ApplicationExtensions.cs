using StackExchange.Redis;
using TraderApi.Alpaca;
using TraderApi.Data;
using TraderApi.Features.Accounts;
using TraderApi.Features.Alerts;
using TraderApi.Features.Assets;
using TraderApi.Features.Orders;
using TraderApi.Features.Portfolio;
using TraderApi.Features.Positions;
using TraderApi.Features.Test;
using TraderApi.Features.Watchlists;
using TraderApi.Features.Webhooks;
using TraderApi.Features.Videos;
using TraderApi.Features.Symbols;

namespace TraderApi.Extensions;

public static class ApplicationExtensions
{
    public static WebApplication MapEndpoints(this WebApplication app)
    {
        app.MapHealthEndpoints();
        app.MapAccountsEndpoints();
        app.MapAssetsEndpoints();
        app.MapPortfolioEndpoints();
        app.MapPositionsEndpoints();
        app.MapOrdersEndpoints();
        app.MapWatchlistsEndpoints();
        app.MapAlertsEndpoints();
        app.MapWebhooksEndpoints();
        app.MapVideoEndpoints();
        app.MapSymbolsEndpoints();
        
        if (app.Environment.IsDevelopment())
        {
            app.MapTestEndpoints();
        }

        return app;
    }

    public static void MapHealthEndpoints(this WebApplication app)
    {
        app.MapGet("/health", async (IServiceProvider serviceProvider) =>
        {
            var status = "healthy";
            var services = new Dictionary<string, object>();
            var warnings = new List<string>();

            // Check database
            try
            {
                using var scope = serviceProvider.CreateScope();
                var db = scope.ServiceProvider.GetService<AppDbContext>();
                if (db != null)
                {
                    await db.Database.CanConnectAsync();
                    services["database"] = new { status = "healthy" };
                }
                else
                {
                    services["database"] = new { status = "not_configured" };
                }
            }
            catch (Exception ex)
            {
                services["database"] = new { status = "unhealthy", error = ex.Message };
                warnings.Add("Database is not available");
            }

            // Check Redis
            try
            {
                var redis = serviceProvider.GetService<IConnectionMultiplexer>();
                if (redis != null && redis.IsConnected)
                {
                    var redisDb = redis.GetDatabase();
                    await redisDb.PingAsync();
                    services["redis"] = new { status = "healthy" };
                }
                else
                {
                    services["redis"] = new { status = "not_connected" };
                    warnings.Add("Redis is not connected");
                }
            }
            catch (Exception ex)
            {
                services["redis"] = new { status = "unhealthy", error = ex.Message };
                warnings.Add("Redis is not available");
            }

            // Check Alpaca (skip if no credentials)
            services["alpaca"] = new { status = "not_configured" };
            
            // Overall status
            if (warnings.Count > 0)
            {
                status = "degraded";
            }

            var health = new
            {
                status,
                timestamp = DateTime.UtcNow,
                services,
                warnings = warnings.Count > 0 ? warnings : null
            };

            return Results.Ok(health);
        })
        .AllowAnonymous()
        .WithName("Health")
        .WithSummary("Health check endpoint")
        .WithTags("Health");
    }

    public static WebApplication UseExceptionHandling(this WebApplication app)
    {
        app.UseExceptionHandler(exceptionHandlerApp =>
        {
            exceptionHandlerApp.Run(async context =>
            {
                context.Response.StatusCode = StatusCodes.Status500InternalServerError;
                context.Response.ContentType = "application/json";

                var exceptionHandlerFeature = context.Features.Get<Microsoft.AspNetCore.Diagnostics.IExceptionHandlerFeature>();
                var exception = exceptionHandlerFeature?.Error;

                var error = new
                {
                    error = "InternalServerError",
                    details = app.Environment.IsDevelopment() 
                        ? exception?.ToString() ?? "An error occurred processing your request"
                        : "An error occurred"
                };

                await context.Response.WriteAsJsonAsync(error);
            });
        });

        return app;
    }
}