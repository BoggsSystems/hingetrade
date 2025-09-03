using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.IdentityModel.Tokens;

namespace TraderApi.Features.Videos;

/// <summary>
/// Service for generating and validating JWT tokens for service-to-service authentication
/// </summary>
public interface IServiceAuthenticationService
{
    string GenerateServiceToken(string serviceName, string[] permissions, TimeSpan? expiresIn = null);
    bool ValidateServiceToken(string token, out ServiceTokenClaims? claims);
    Task<string> AuthenticateServiceRequestAsync(HttpRequestMessage request, CancellationToken cancellationToken = default);
}

public class ServiceAuthenticationService : IServiceAuthenticationService
{
    private readonly IConfiguration _configuration;
    private readonly ILogger<ServiceAuthenticationService> _logger;
    private readonly string _secretKey;
    private readonly string _issuer;
    private readonly string _audience;

    public ServiceAuthenticationService(
        IConfiguration configuration,
        ILogger<ServiceAuthenticationService> logger)
    {
        _configuration = configuration;
        _logger = logger;
        _secretKey = configuration["ServiceAuthentication:SecretKey"] ?? "default-service-secret-key-for-development-only";
        _issuer = configuration["ServiceAuthentication:Issuer"] ?? "hingetrade-api";
        _audience = configuration["ServiceAuthentication:Audience"] ?? "creator-studio-api";
    }

    public string GenerateServiceToken(string serviceName, string[] permissions, TimeSpan? expiresIn = null)
    {
        var expiration = expiresIn ?? TimeSpan.FromHours(4);
        var expires = DateTime.UtcNow.Add(expiration);

        var claims = new[]
        {
            new Claim("service_name", serviceName),
            new Claim("permissions", string.Join(",", permissions)),
            new Claim(JwtRegisteredClaimNames.Iss, _issuer),
            new Claim(JwtRegisteredClaimNames.Aud, _audience),
            new Claim(JwtRegisteredClaimNames.Exp, ((DateTimeOffset)expires).ToUnixTimeSeconds().ToString()),
            new Claim(JwtRegisteredClaimNames.Iat, ((DateTimeOffset)DateTime.UtcNow).ToUnixTimeSeconds().ToString()),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
        };

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_secretKey));
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var token = new JwtSecurityToken(
            issuer: _issuer,
            audience: _audience,
            claims: claims,
            expires: expires,
            signingCredentials: credentials
        );

        var tokenString = new JwtSecurityTokenHandler().WriteToken(token);
        
        _logger.LogDebug("Generated service token for {ServiceName} with permissions: {Permissions}", 
            serviceName, string.Join(", ", permissions));
        
        return tokenString;
    }

    public bool ValidateServiceToken(string token, out ServiceTokenClaims? claims)
    {
        claims = null;

        try
        {
            var tokenHandler = new JwtSecurityTokenHandler();
            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_secretKey));

            var validationParameters = new TokenValidationParameters
            {
                ValidateIssuerSigningKey = true,
                IssuerSigningKey = key,
                ValidateIssuer = true,
                ValidIssuer = _issuer,
                ValidateAudience = true,
                ValidAudience = _audience,
                ValidateLifetime = true,
                ClockSkew = TimeSpan.FromMinutes(5) // Allow 5 minutes clock skew
            };

            var principal = tokenHandler.ValidateToken(token, validationParameters, out var validatedToken);
            
            var serviceName = principal.FindFirst("service_name")?.Value;
            var permissionsString = principal.FindFirst("permissions")?.Value;
            var permissions = permissionsString?.Split(',') ?? Array.Empty<string>();

            if (string.IsNullOrEmpty(serviceName))
            {
                _logger.LogWarning("Service token missing service_name claim");
                return false;
            }

            claims = new ServiceTokenClaims(serviceName, permissions);
            
            _logger.LogDebug("Successfully validated service token for {ServiceName}", serviceName);
            return true;
        }
        catch (SecurityTokenExpiredException ex)
        {
            _logger.LogWarning("Service token expired: {Message}", ex.Message);
            return false;
        }
        catch (SecurityTokenException ex)
        {
            _logger.LogWarning("Invalid service token: {Message}", ex.Message);
            return false;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unexpected error validating service token");
            return false;
        }
    }

    public Task<string> AuthenticateServiceRequestAsync(HttpRequestMessage request, CancellationToken cancellationToken = default)
    {
        // Generate a service token for HingeTrade API with video permissions
        var token = GenerateServiceToken("hingetrade-api", new[] { "videos:read", "videos:write" });
        
        // Add the Authorization header to the request
        request.Headers.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", token);
        
        _logger.LogDebug("Added service authentication to request for {RequestUri}", request.RequestUri);
        
        return Task.FromResult(token);
    }
}

/// <summary>
/// Claims extracted from a service JWT token
/// </summary>
public record ServiceTokenClaims(
    string ServiceName,
    string[] Permissions
)
{
    public bool HasPermission(string permission) => 
        Permissions.Contains(permission, StringComparer.OrdinalIgnoreCase);
};