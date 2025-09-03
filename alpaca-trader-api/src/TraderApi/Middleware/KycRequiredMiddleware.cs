using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using TraderApi.Features.Auth.Data;
using TraderApi.Features.Auth.Models;

namespace TraderApi.Middleware;

public class KycRequiredMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<KycRequiredMiddleware> _logger;

    public KycRequiredMiddleware(RequestDelegate next, ILogger<KycRequiredMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context, AuthDbContext authDb)
    {
        // Skip for non-authenticated routes
        if (!context.User.Identity?.IsAuthenticated ?? true)
        {
            await _next(context);
            return;
        }

        // Skip for auth and KYC endpoints
        var path = context.Request.Path.Value?.ToLower() ?? "";
        if (path.StartsWith("/api/auth") || path.StartsWith("/api/kyc") || 
            path.StartsWith("/swagger") || path.StartsWith("/api/test"))
        {
            await _next(context);
            return;
        }
        
        // In development, allow funding, account, orders, and positions endpoints for testing
        var isDevelopment = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT") == "Development";
        if (isDevelopment && (path.StartsWith("/api/funding") || 
                               path.StartsWith("/api/account") || 
                               path.StartsWith("/api/orders") ||
                               path.StartsWith("/api/positions") ||
                               path.StartsWith("/api/portfolio") ||
                               path.StartsWith("/api/layouts") ||
                               path.StartsWith("/api/market-data") ||
                               path.StartsWith("/api/symbols") ||
                               path.StartsWith("/api/watchlists") ||
                               path.StartsWith("/api/videos") ||
                               path.StartsWith("/hubs/")))
        {
            _logger.LogInformation($"Allowing access in development for path: {path}");
            await _next(context);
            return;
        }

        // Check KYC status
        var userId = context.User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (!string.IsNullOrEmpty(userId) && Guid.TryParse(userId, out var userGuid))
        {
            var user = await authDb.Users
                .AsNoTracking()
                .FirstOrDefaultAsync(u => u.Id == userGuid);

            if (user != null)
            {
                // Allow read-only endpoints for users in KYC progress
                var isReadOnly = context.Request.Method == "GET" && 
                    (path.StartsWith("/api/market") || path.StartsWith("/api/portfolio/summary") || path.StartsWith("/api/symbols"));

                if (user.KycStatus != KycStatus.Approved && !isReadOnly)
                {
                    _logger.LogWarning($"User {user.Email} attempted to access {path} without approved KYC");
                    
                    context.Response.StatusCode = 403;
                    context.Response.Headers["X-KYC-Status"] = user.KycStatus.ToString();
                    
                    await context.Response.WriteAsJsonAsync(new
                    {
                        error = "KYC_REQUIRED",
                        message = "KYC verification required to access this resource",
                        kycStatus = user.KycStatus.ToString()
                    });
                    
                    return;
                }
            }
        }

        await _next(context);
    }
}

// Extension method to add the middleware
public static class KycRequiredMiddlewareExtensions
{
    public static IApplicationBuilder UseKycRequired(this IApplicationBuilder builder)
    {
        return builder.UseMiddleware<KycRequiredMiddleware>();
    }
}