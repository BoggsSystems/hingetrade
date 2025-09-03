using System.Security.Claims;
using System.Text.Encodings.Web;
using Microsoft.AspNetCore.Authentication;
using Microsoft.Extensions.Options;

namespace TraderApi.Security;

/// <summary>
/// Demo authentication handler for testing without Auth0
/// WARNING: This should NEVER be used in production!
/// </summary>
public class DemoAuthenticationHandler : AuthenticationHandler<AuthenticationSchemeOptions>
{
    public const string SchemeName = "Demo";
    
    public DemoAuthenticationHandler(
        IOptionsMonitor<AuthenticationSchemeOptions> options,
        ILoggerFactory logger,
        UrlEncoder encoder)
        : base(options, logger, encoder)
    {
    }

    protected override Task<AuthenticateResult> HandleAuthenticateAsync()
    {
        // Check if demo auth is enabled
        var isDemoEnabled = Context.RequestServices
            .GetRequiredService<IConfiguration>()
            .GetValue<bool>("Auth:EnableDemoMode");
            
        if (!isDemoEnabled)
        {
            return Task.FromResult(AuthenticateResult.NoResult());
        }

        // Create demo user claims
        var claims = new[]
        {
            new Claim(ClaimTypes.NameIdentifier, "demo-user-123"),
            new Claim(ClaimTypes.Name, "Demo User"),
            new Claim(ClaimTypes.Email, "demo@example.com"),
            new Claim("sub", "demo-user-123") // Auth0 style sub claim
        };

        var identity = new ClaimsIdentity(claims, SchemeName);
        var principal = new ClaimsPrincipal(identity);
        var ticket = new AuthenticationTicket(principal, SchemeName);

        Logger.LogWarning("Demo authentication is enabled - this should not be used in production!");
        
        return Task.FromResult(AuthenticateResult.Success(ticket));
    }
}

public static class DemoAuthenticationExtensions
{
    public static AuthenticationBuilder AddDemoAuthentication(
        this AuthenticationBuilder builder)
    {
        return builder.AddScheme<AuthenticationSchemeOptions, DemoAuthenticationHandler>(
            DemoAuthenticationHandler.SchemeName, 
            options => { });
    }
}