using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using TraderApi.Features.Auth.Data;
using TraderApi.Features.Auth.Services;

namespace TraderApi.Features.Auth.Extensions;

public static class AuthExtensions
{
    public static IServiceCollection AddCustomAuthentication(
        this IServiceCollection services, 
        IConfiguration configuration)
    {
        // Add Auth DbContext
        services.AddDbContext<AuthDbContext>(options =>
            options.UseNpgsql(configuration.GetConnectionString("Postgres")));
        
        // Configure JWT settings
        var jwtSection = configuration.GetSection("Jwt");
        services.Configure<JwtSettings>(jwtSection);
        
        var jwtSettings = jwtSection.Get<JwtSettings>() ?? new JwtSettings
        {
            SecretKey = "your-256-bit-secret-key-for-development-only",
            Issuer = "hingetrade-api",
            Audience = "hingetrade-app",
            AccessTokenExpirationMinutes = 15,
            RefreshTokenExpirationDays = 30
        };
        
        // Add services
        services.AddScoped<IPasswordService, PasswordService>();
        services.AddScoped<ITokenService, TokenService>();
        services.AddScoped<IUserService, UserService>();
        services.AddScoped<IRefreshTokenService, RefreshTokenService>();
        
        // Configure JWT authentication
        services.AddAuthentication(options =>
        {
            options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
            options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
        })
        .AddJwtBearer(options =>
        {
            options.TokenValidationParameters = new TokenValidationParameters
            {
                ValidateIssuerSigningKey = true,
                IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSettings.SecretKey)),
                ValidateIssuer = true,
                ValidIssuer = jwtSettings.Issuer,
                ValidateAudience = true,
                ValidAudience = jwtSettings.Audience,
                ValidateLifetime = true,
                ClockSkew = TimeSpan.Zero
            };
            
            // Configure events for debugging and SignalR support
            options.Events = new JwtBearerEvents
            {
                OnAuthenticationFailed = context =>
                {
                    if (context.Exception.GetType() == typeof(SecurityTokenExpiredException))
                    {
                        context.Response.Headers.Append("Token-Expired", "true");
                    }
                    return Task.CompletedTask;
                },
                OnTokenValidated = context =>
                {
                    // Additional validation if needed
                    return Task.CompletedTask;
                },
                OnMessageReceived = context =>
                {
                    // SignalR sends the token in a query string when using WebSockets
                    var accessToken = context.Request.Query["access_token"];
                    
                    // If the request is for our hub...
                    var path = context.HttpContext.Request.Path;
                    if (!string.IsNullOrEmpty(accessToken) &&
                        (path.StartsWithSegments("/hubs")))
                    {
                        // Read the token out of the query string
                        context.Token = accessToken;
                    }
                    return Task.CompletedTask;
                }
            };
        });
        
        // Add authorization policies
        services.AddAuthorization(options =>
        {
            // Default policy requires authenticated user
            options.DefaultPolicy = new AuthorizationPolicyBuilder()
                .RequireAuthenticatedUser()
                .Build();
                
            // Admin policy
            options.AddPolicy("AdminOnly", policy =>
                policy.RequireRole("Admin"));
                
            // Verified email policy
            options.AddPolicy("VerifiedEmail", policy =>
                policy.RequireClaim("email_verified", "True"));
        });
        
        return services;
    }
    
    public static async Task InitializeAuthDatabaseAsync(this WebApplication app)
    {
        using var scope = app.Services.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<AuthDbContext>();
        
        // Apply migrations
        await context.Database.MigrateAsync();
        
        // Seed roles if they don't exist
        if (!await context.Roles.AnyAsync())
        {
            // Roles are seeded in the model configuration
            await context.SaveChangesAsync();
        }
    }
}