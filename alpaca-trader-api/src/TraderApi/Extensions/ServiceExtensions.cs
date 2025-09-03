using System.Threading.RateLimiting;
using FluentValidation;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using StackExchange.Redis;
using TraderApi.Alpaca;
using TraderApi.Data;
using TraderApi.Features.Accounts;
using TraderApi.Features.Alerts;
using TraderApi.Features.Orders;
using TraderApi.Features.Orders.Risk;
using TraderApi.Features.Positions;
using TraderApi.Features.Watchlists;
using TraderApi.Features.Funding;
using TraderApi.Features.Layouts;
using TraderApi.Features.Videos;
using TraderApi.Notifications;
using TraderApi.Security;

namespace TraderApi.Extensions;

public static class ServiceExtensions
{
    public static IServiceCollection AddApplicationServices(this IServiceCollection services, IConfiguration configuration)
    {
        // Configuration
        var appSettings = configuration.Get<AppSettings>() ?? new AppSettings();
        services.AddSingleton(appSettings);
        services.AddSingleton(appSettings.Alpaca);
        services.AddSingleton(appSettings.Risk);
        services.AddSingleton(appSettings.Webhook);
        services.AddSingleton(appSettings.Notifications.Smtp);

        // Database
        services.AddDbContext<AppDbContext>(options =>
            options.UseNpgsql(appSettings.ConnectionStrings.Postgres));

        // Redis
        services.AddSingleton<IConnectionMultiplexer>(sp =>
        {
            var configuration = ConfigurationOptions.Parse(appSettings.Redis.Connection);
            configuration.AbortOnConnectFail = false;
            return ConnectionMultiplexer.Connect(configuration);
        });

        // Security
        services.AddSingleton<IKeyProtector>(sp => 
            new KeyProtector(appSettings.KeyProtection.Key));

        // HTTP Clients
        services.AddHttpClient<IAlpacaClient, AlpacaClient>();
        services.AddHttpClient<IPlaidService, PlaidService>();
        
        // Alpaca Services
        services.AddScoped<IAlpacaStreamingClient, AlpacaStreamingClient>();

        // Feature Services
        services.AddScoped<IAccountsService, AccountsService>();
        services.AddScoped<IPositionsService, PositionsService>();
        services.AddScoped<IOrdersService, OrdersService>();
        services.AddScoped<IRiskService, RiskService>();
        services.AddScoped<IWatchlistsService, WatchlistsService>();
        services.AddScoped<IAlertsService, AlertsService>();
        services.AddScoped<TraderApi.Features.Assets.IAssetValidationService, TraderApi.Features.Assets.AssetValidationService>();
        services.AddScoped<ILayoutsService, LayoutsService>();
        
        // Video Services
        services.AddScoped<IServiceAuthenticationService, ServiceAuthenticationService>();
        services.AddHttpClient<ICreatorStudioClient, CreatorStudioClient>(client =>
        {
            var creatorStudioUrl = configuration["CreatorStudio:ApiUrl"] ?? "http://localhost:5155/api";
            client.BaseAddress = new Uri(creatorStudioUrl);
            client.Timeout = TimeSpan.FromSeconds(30);
        });
        services.AddScoped<IVideoService, VideoService>();
        services.AddScoped<IUserMappingService, UserMappingService>();
        services.AddMemoryCache(); // For video caching
        
        // Market Data
        services.AddHttpClient<TraderApi.Features.MarketData.IMarketDataRestClient, TraderApi.Features.MarketData.AlpacaMarketDataRestClient>();
        services.AddHttpClient<TraderApi.Features.MarketData.IYahooFinanceClient, TraderApi.Features.MarketData.YahooFinanceClient>();
        services.AddHttpClient<TraderApi.Features.MarketData.AlphaVantageClient>();
        services.AddSingleton<TraderApi.Features.MarketData.IMarketDataService, TraderApi.Features.MarketData.AlpacaMarketDataService>();
        services.AddHostedService(sp => sp.GetRequiredService<TraderApi.Features.MarketData.IMarketDataService>() as TraderApi.Features.MarketData.AlpacaMarketDataService);
        
        // SignalR with JSON configuration
        services.AddSignalR(options =>
        {
            options.EnableDetailedErrors = true;
        })
        .AddJsonProtocol(options =>
        {
            options.PayloadSerializerOptions.PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase;
        });
        
        // Notifications
        services.AddScoped<IEmailNotifier, EmailNotifier>();

        // Background Services
        // TODO: Re-enable when Redis is available
        // services.AddHostedService<AlertsWorker>();

        // Validators
        services.AddValidatorsFromAssemblyContaining<Program>();

        return services;
    }

    // Auth0 authentication has been replaced with custom authentication in Program.cs

    public static IServiceCollection AddRateLimiting(this IServiceCollection services, IConfiguration configuration)
    {
        var rateLimitSettings = configuration.GetSection("RateLimit").Get<RateLimitSettings>() ?? new RateLimitSettings();

        services.AddRateLimiter(options =>
        {
            options.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(httpContext =>
            {
                var userIdentifier = httpContext.User?.Identity?.IsAuthenticated == true
                    ? httpContext.User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value ?? "anonymous"
                    : httpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown";

                return RateLimitPartition.GetFixedWindowLimiter(
                    partitionKey: userIdentifier,
                    factory: partition => new FixedWindowRateLimiterOptions
                    {
                        AutoReplenishment = true,
                        PermitLimit = rateLimitSettings.PermitLimit,
                        Window = TimeSpan.FromMinutes(rateLimitSettings.WindowInMinutes)
                    });
            });

            options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
        });

        return services;
    }

    public static IServiceCollection AddSwagger(this IServiceCollection services)
    {
        services.AddEndpointsApiExplorer();
        services.AddSwaggerGen(options =>
        {
            options.SwaggerDoc("v1", new OpenApiInfo
            {
                Title = "Alpaca Trader API",
                Version = "v1",
                Description = "Production-ready backend for Alpaca-powered trading"
            });

            options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
            {
                Description = "JWT Authorization header using the Bearer scheme",
                Name = "Authorization",
                In = ParameterLocation.Header,
                Type = SecuritySchemeType.Http,
                Scheme = "bearer"
            });

            options.AddSecurityRequirement(new OpenApiSecurityRequirement
            {
                {
                    new OpenApiSecurityScheme
                    {
                        Reference = new OpenApiReference
                        {
                            Type = ReferenceType.SecurityScheme,
                            Id = "Bearer"
                        }
                    },
                    Array.Empty<string>()
                }
            });
        });

        return services;
    }

    // CORS configuration has been moved to Program.cs with authentication support
}