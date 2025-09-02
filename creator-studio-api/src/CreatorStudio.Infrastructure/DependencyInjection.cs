using System.Text;
using CreatorStudio.Application.Common.Interfaces;
using CreatorStudio.Domain.Entities;
using CreatorStudio.Domain.Interfaces;
using CreatorStudio.Infrastructure.Data;
using CreatorStudio.Infrastructure.Repositories;
using CreatorStudio.Infrastructure.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.IdentityModel.Tokens;

namespace CreatorStudio.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(
        this IServiceCollection services, 
        IConfiguration configuration)
    {
        // Database
        services.AddDbContext<CreatorStudioDbContext>(options =>
        {
            var connectionString = configuration.GetConnectionString("DefaultConnection");
            if (string.IsNullOrEmpty(connectionString))
            {
                throw new InvalidOperationException("Database connection string 'DefaultConnection' is required");
            }
            
            options.UseNpgsql(connectionString, b => 
            {
                b.MigrationsAssembly(typeof(CreatorStudioDbContext).Assembly.FullName);
                b.EnableRetryOnFailure(
                    maxRetryCount: 3,
                    maxRetryDelay: TimeSpan.FromSeconds(5),
                    errorCodesToAdd: null);
            });
            
            // Enable sensitive data logging in development
            var isDevelopment = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT") == "Development";
            if (isDevelopment)
            {
                options.EnableSensitiveDataLogging();
                options.EnableDetailedErrors();
            }
        });

        // Identity
        services.AddIdentity<User, IdentityRole<Guid>>(options =>
        {
            // Password settings
            options.Password.RequireDigit = true;
            options.Password.RequiredLength = 8;
            options.Password.RequireNonAlphanumeric = false;
            options.Password.RequireUppercase = true;
            options.Password.RequireLowercase = true;
            
            // User settings
            options.User.RequireUniqueEmail = true;
            options.User.AllowedUserNameCharacters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._@+";
            
            // Lockout settings
            options.Lockout.DefaultLockoutTimeSpan = TimeSpan.FromMinutes(5);
            options.Lockout.MaxFailedAccessAttempts = 5;
            options.Lockout.AllowedForNewUsers = true;
        })
        .AddEntityFrameworkStores<CreatorStudioDbContext>()
        .AddDefaultTokenProviders();

        // JWT Authentication
        var jwtSecret = configuration["JWT:Secret"] ?? "your-super-secret-key-that-is-at-least-32-characters-long";
        var key = Encoding.ASCII.GetBytes(jwtSecret);
        
        services.AddAuthentication(options =>
        {
            options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
            options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
        })
        .AddJwtBearer(options =>
        {
            options.RequireHttpsMetadata = false; // Set to true in production
            options.SaveToken = true;
            options.TokenValidationParameters = new TokenValidationParameters
            {
                ValidateIssuerSigningKey = true,
                IssuerSigningKey = new SymmetricSecurityKey(key),
                ValidateIssuer = true,
                ValidIssuer = configuration["JWT:Issuer"] ?? "CreatorStudio",
                ValidateAudience = true,
                ValidAudience = configuration["JWT:Audience"] ?? "CreatorStudio",
                ValidateLifetime = true,
                ClockSkew = TimeSpan.Zero
            };
        });

        // JWT Token Service
        services.AddScoped<IJwtTokenService, JwtTokenService>();

        // Repository pattern
        services.AddScoped<IUnitOfWork, UnitOfWork>();
        services.AddScoped(typeof(IRepository<>), typeof(Repository<>));

        // Video processing service
        services.AddScoped<IVideoProcessingService, CloudinaryVideoService>();

        // Background Services
        services.AddHostedService<VideoAnalyticsAggregationService>();

        // Health checks
        services.AddHealthChecks()
            .AddDbContextCheck<CreatorStudioDbContext>("database")
            .AddCheck("cloudinary", () => 
            {
                var cloudinaryUrl = configuration.GetConnectionString("Cloudinary");
                return string.IsNullOrEmpty(cloudinaryUrl) 
                    ? Microsoft.Extensions.Diagnostics.HealthChecks.HealthCheckResult.Unhealthy("Cloudinary connection string not configured")
                    : Microsoft.Extensions.Diagnostics.HealthChecks.HealthCheckResult.Healthy("Cloudinary configured");
            });

        return services;
    }
}