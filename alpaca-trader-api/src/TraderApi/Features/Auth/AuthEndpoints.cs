using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Mvc;
using TraderApi.Features.Auth.Dtos;
using TraderApi.Features.Auth.Models;
using TraderApi.Features.Auth.Services;
using TraderApi.Data;
using TraderApi.Security;
using Microsoft.EntityFrameworkCore;
using TraderApi.Alpaca;
using TraderApi.Alpaca.Models;

namespace TraderApi.Features.Auth;

public static class AuthEndpoints
{
    public static void MapAuthEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/auth")
            .WithTags("Authentication");
            
        group.MapPost("/register", Register)
            .WithName("Register")
            .WithSummary("Register a new user")
            .AllowAnonymous();
            
        group.MapPost("/login", Login)
            .WithName("Login")
            .WithSummary("Login with email/username and password")
            .AllowAnonymous();
            
        group.MapPost("/refresh", RefreshToken)
            .WithName("RefreshToken")
            .WithSummary("Refresh access token using refresh token")
            .AllowAnonymous();
            
        group.MapPost("/logout", Logout)
            .WithName("Logout")
            .WithSummary("Logout and revoke refresh token")
            .RequireAuthorization();
            
        group.MapPost("/forgot-password", ForgotPassword)
            .WithName("ForgotPassword")
            .WithSummary("Request password reset email")
            .AllowAnonymous();
            
        group.MapPost("/reset-password", ResetPassword)
            .WithName("ResetPassword")
            .WithSummary("Reset password using token from email")
            .AllowAnonymous();
    }
    
    private static async Task<Results<Ok<AuthResponse>, BadRequest<ValidationProblemDetails>>> Register(
        RegisterRequest request,
        IUserService userService,
        IPasswordService passwordService,
        ITokenService tokenService,
        IRefreshTokenService refreshTokenService,
        AppDbContext appDbContext,
        IConfiguration configuration,
        IWebHostEnvironment environment,
        IKeyProtector keyProtector,
        IAlpacaClient alpacaClient)
    {
        // Validate password strength
        if (!passwordService.IsPasswordStrong(request.Password, out var errors))
        {
            return TypedResults.BadRequest(new ValidationProblemDetails
            {
                Errors = new Dictionary<string, string[]> { ["password"] = errors }
            });
        }
        
        // Check if email exists
        if (await userService.EmailExistsAsync(request.Email))
        {
            return TypedResults.BadRequest(new ValidationProblemDetails
            {
                Errors = new Dictionary<string, string[]> { ["email"] = new[] { "Email already registered" } }
            });
        }
        
        // Check if username exists
        if (await userService.UsernameExistsAsync(request.Username))
        {
            return TypedResults.BadRequest(new ValidationProblemDetails
            {
                Errors = new Dictionary<string, string[]> { ["username"] = new[] { "Username already taken" } }
            });
        }
        
        // Create user
        var passwordHash = passwordService.HashPassword(request.Password);
        var user = await userService.CreateUserAsync(request.Email, request.Username, passwordHash);
        
        // Generate tokens
        var roles = await userService.GetUserRolesAsync(user.Id);
        var accessToken = tokenService.GenerateAccessToken(user, roles);
        var refreshToken = tokenService.GenerateRefreshToken();
        
        // Store refresh token
        await refreshTokenService.CreateRefreshTokenAsync(user.Id, refreshToken);
        
        // Create trading user and link test Alpaca account in development
        if (environment.IsDevelopment())
        {
            Console.WriteLine($"[AUTO-LINK] Development environment detected, starting auto-linking process for user {user.Email}");
            var brokerAccountId = await CreateTradingUserWithTestAlpacaAsync(user, appDbContext, configuration, keyProtector, alpacaClient);
            Console.WriteLine($"[AUTO-LINK] CreateTradingUserWithTestAlpacaAsync returned broker account ID: {brokerAccountId}");
            
            if (!string.IsNullOrEmpty(brokerAccountId))
            {
                // Update the auth user with the Alpaca account ID
                Console.WriteLine($"[AUTO-LINK] Setting user.AlpacaAccountId to: {brokerAccountId}");
                user.AlpacaAccountId = brokerAccountId;
                await userService.UpdateUserAsync(user);
                Console.WriteLine($"[AUTO-LINK] Successfully updated user {user.Email} with AlpacaAccountId: {brokerAccountId}");
            }
            else
            {
                Console.WriteLine($"[AUTO-LINK] WARNING: No broker account ID returned for user {user.Email}");
            }
        }
        else
        {
            Console.WriteLine($"[AUTO-LINK] Not in development environment, skipping auto-linking for user {user.Email}");
        }
        
        return TypedResults.Ok(new AuthResponse(
            AccessToken: accessToken,
            RefreshToken: refreshToken,
            ExpiresIn: 900, // 15 minutes in seconds
            User: new UserDto(
                Id: user.Id,
                Email: user.Email,
                Username: user.Username,
                EmailVerified: user.EmailVerified,
                CreatedAt: user.CreatedAt,
                Roles: roles,
                KycStatus: user.KycStatus.ToString(),
                KycSubmittedAt: user.KycSubmittedAt,
                KycApprovedAt: user.KycApprovedAt
            )
        ));
    }
    
    private static async Task<Results<Ok<AuthResponse>, UnauthorizedHttpResult>> Login(
        LoginRequest request,
        IUserService userService,
        IPasswordService passwordService,
        ITokenService tokenService,
        IRefreshTokenService refreshTokenService)
    {
        // Find user by email or username
        Auth.Models.User? user = null;
        if (request.EmailOrUsername.Contains('@'))
        {
            user = await userService.GetByEmailAsync(request.EmailOrUsername);
        }
        else
        {
            user = await userService.GetByUsernameAsync(request.EmailOrUsername);
        }
        
        if (user == null || !passwordService.VerifyPassword(request.Password, user.PasswordHash))
        {
            return TypedResults.Unauthorized();
        }
        
        // Generate tokens
        var roles = await userService.GetUserRolesAsync(user.Id);
        var accessToken = tokenService.GenerateAccessToken(user, roles);
        var refreshToken = tokenService.GenerateRefreshToken();
        
        // Store refresh token
        await refreshTokenService.CreateRefreshTokenAsync(user.Id, refreshToken);
        
        return TypedResults.Ok(new AuthResponse(
            AccessToken: accessToken,
            RefreshToken: refreshToken,
            ExpiresIn: 900, // 15 minutes in seconds
            User: new UserDto(
                Id: user.Id,
                Email: user.Email,
                Username: user.Username,
                EmailVerified: user.EmailVerified,
                CreatedAt: user.CreatedAt,
                Roles: roles,
                KycStatus: user.KycStatus.ToString(),
                KycSubmittedAt: user.KycSubmittedAt,
                KycApprovedAt: user.KycApprovedAt
            )
        ));
    }
    
    private static async Task<Results<Ok<AuthResponse>, UnauthorizedHttpResult>> RefreshToken(
        RefreshTokenRequest request,
        IUserService userService,
        ITokenService tokenService,
        IRefreshTokenService refreshTokenService)
    {
        // Validate refresh token
        var storedToken = await refreshTokenService.GetActiveTokenAsync(request.RefreshToken);
        if (storedToken == null)
        {
            return TypedResults.Unauthorized();
        }
        
        var user = storedToken.User;
        var roles = await userService.GetUserRolesAsync(user.Id);
        
        // Generate new tokens
        var newAccessToken = tokenService.GenerateAccessToken(user, roles);
        var newRefreshToken = tokenService.GenerateRefreshToken();
        
        // Revoke old token and create new one
        await refreshTokenService.RevokeTokenAsync(request.RefreshToken);
        await refreshTokenService.CreateRefreshTokenAsync(user.Id, newRefreshToken);
        
        return TypedResults.Ok(new AuthResponse(
            AccessToken: newAccessToken,
            RefreshToken: newRefreshToken,
            ExpiresIn: 900, // 15 minutes in seconds
            User: new UserDto(
                Id: user.Id,
                Email: user.Email,
                Username: user.Username,
                EmailVerified: user.EmailVerified,
                CreatedAt: user.CreatedAt,
                Roles: roles,
                KycStatus: user.KycStatus.ToString(),
                KycSubmittedAt: user.KycSubmittedAt,
                KycApprovedAt: user.KycApprovedAt
            )
        ));
    }
    
    private static async Task<NoContent> Logout(
        HttpContext context,
        IRefreshTokenService refreshTokenService)
    {
        var userIdClaim = context.User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (Guid.TryParse(userIdClaim, out var userId))
        {
            // Revoke all user's refresh tokens
            await refreshTokenService.RevokeAllUserTokensAsync(userId);
        }
        
        return TypedResults.NoContent();
    }
    
    private static async Task<Results<NoContent, BadRequest<ValidationProblemDetails>>> ForgotPassword(
        ForgotPasswordRequest request,
        IUserService userService)
    {
        // For security, always return success even if email doesn't exist
        var user = await userService.GetByEmailAsync(request.Email);
        if (user != null)
        {
            // TODO: Generate password reset token and send email
            // For now, we'll just log it
            Console.WriteLine($"Password reset requested for {user.Email}");
        }
        
        return TypedResults.NoContent();
    }
    
    private static Task<Results<NoContent, BadRequest<ValidationProblemDetails>>> ResetPassword(
        ResetPasswordRequest request,
        IUserService userService,
        IPasswordService passwordService)
    {
        // TODO: Implement password reset token validation
        // For now, return not implemented
        
        return Task.FromResult<Results<NoContent, BadRequest<ValidationProblemDetails>>>(
            TypedResults.BadRequest(new ValidationProblemDetails
            {
                Errors = new Dictionary<string, string[]> 
                { 
                    ["token"] = new[] { "Password reset not implemented yet" } 
                }
            }));
    }
    
    private static async Task<string?> CreateTradingUserWithTestAlpacaAsync(
        Auth.Models.User authUser, 
        AppDbContext dbContext, 
        IConfiguration configuration,
        IKeyProtector keyProtector,
        IAlpacaClient alpacaClient)
    {
        Console.WriteLine($"[AUTO-LINK] Starting CreateTradingUserWithTestAlpacaAsync for user {authUser.Email}");
        
        // Create the trading user
        var tradingUser = new TraderApi.Data.User
        {
            Id = authUser.Id,
            AuthSub = $"auth|{authUser.Id}",
            Email = authUser.Email,
            CreatedAt = authUser.CreatedAt
        };
        
        Console.WriteLine($"[AUTO-LINK] Created trading user record for {authUser.Email}");
        dbContext.Users.Add(tradingUser);
        
        // Get test Alpaca credentials from configuration
        // Try environment variables directly since DotNetEnv loads them
        var apiKeyId = Environment.GetEnvironmentVariable("ALPACA_API_KEY_ID") ?? configuration["ALPACA_API_KEY_ID"];
        var apiSecret = Environment.GetEnvironmentVariable("ALPACA_API_SECRET") ?? configuration["ALPACA_API_SECRET"];
        var alpacaEnv = Environment.GetEnvironmentVariable("ALPACA_ENV") ?? configuration["ALPACA_ENV"] ?? "sandbox";
        
        Console.WriteLine($"[AUTO-LINK] Retrieved credentials - apiKeyId: {(string.IsNullOrEmpty(apiKeyId) ? "MISSING" : $"{apiKeyId.Substring(0, Math.Min(8, apiKeyId.Length))}...")}, apiSecret: {(string.IsNullOrEmpty(apiSecret) ? "MISSING" : "Present")}, env: {alpacaEnv}");
        
        if (!string.IsNullOrEmpty(apiKeyId) && !string.IsNullOrEmpty(apiSecret))
        {
            // For development/testing with Broker API, we'll use a test account ID
            // In production, you would create a real broker account via the Alpaca API
            var brokerAccountId = $"TEST_{authUser.Id.ToString().Replace("-", "").Substring(0, 8).ToUpper()}";
            Console.WriteLine($"[AUTO-LINK] Generated broker account ID: {brokerAccountId}");
            
            try
            {
                // Create Alpaca link with encrypted test credentials
                var alpacaLink = new TraderApi.Data.AlpacaLink
                {
                    Id = Guid.NewGuid(),
                    UserId = authUser.Id,
                    AccountId = brokerAccountId,
                    ApiKeyId = keyProtector.Encrypt(apiKeyId),
                    ApiSecret = keyProtector.Encrypt(apiSecret),
                    Env = alpacaEnv == "sandbox" ? "paper" : alpacaEnv,
                    IsBrokerApi = alpacaEnv == "sandbox",
                    BrokerAccountId = brokerAccountId,
                    CreatedAt = DateTime.UtcNow
                };
                
                Console.WriteLine($"[AUTO-LINK] Created AlpacaLink record with ID: {alpacaLink.Id}");
                dbContext.AlpacaLinks.Add(alpacaLink);
                
                Console.WriteLine($"[AUTO-LINK] Saving changes to database...");
                await dbContext.SaveChangesAsync();
                Console.WriteLine($"[AUTO-LINK] Database changes saved successfully");
                
                Console.WriteLine($"[AUTO-LINK] Created test broker account for user {authUser.Email} with ID: {brokerAccountId}");
                return brokerAccountId;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[AUTO-LINK] ERROR creating AlpacaLink: {ex.Message}");
                Console.WriteLine($"[AUTO-LINK] Stack trace: {ex.StackTrace}");
                
                // Still save the trading user even if Alpaca linking fails
                await dbContext.SaveChangesAsync();
                return null;
            }
        }
        else
        {
            Console.WriteLine($"[AUTO-LINK] WARNING: Missing Alpaca credentials - cannot create auto-link");
            Console.WriteLine($"[AUTO-LINK] apiKeyId null/empty: {string.IsNullOrEmpty(apiKeyId)}");
            Console.WriteLine($"[AUTO-LINK] apiSecret null/empty: {string.IsNullOrEmpty(apiSecret)}");
        }
        
        Console.WriteLine($"[AUTO-LINK] Saving trading user without Alpaca link...");
        await dbContext.SaveChangesAsync();
        Console.WriteLine($"[AUTO-LINK] Trading user saved without Alpaca link");
        return null;
    }
}