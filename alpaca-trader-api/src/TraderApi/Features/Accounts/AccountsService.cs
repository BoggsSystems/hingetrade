using Microsoft.EntityFrameworkCore;
using TraderApi.Alpaca;
using TraderApi.Data;
using TraderApi.Security;
using TraderApi.Features.Auth.Data;

namespace TraderApi.Features.Accounts;

public interface IAccountsService
{
    Task<AccountDto> GetAccountAsync(Guid userId);
    Task<LinkAccountResponse> LinkAccountAsync(Guid userId, LinkAccountRequest request);
    Task<UserProfileDto> GetUserProfileAsync(string authSub);
}

public class AccountsService : IAccountsService
{
    private readonly AppDbContext _db;
    private readonly AuthDbContext _authDb;
    private readonly IAlpacaClient _alpacaClient;
    private readonly IKeyProtector _keyProtector;
    private readonly ILogger<AccountsService> _logger;
    private readonly AlpacaSettings _alpacaSettings;

    public AccountsService(
        AppDbContext db,
        AuthDbContext authDb,
        IAlpacaClient alpacaClient,
        IKeyProtector keyProtector,
        ILogger<AccountsService> logger,
        AlpacaSettings alpacaSettings)
    {
        _db = db;
        _authDb = authDb;
        _alpacaClient = alpacaClient;
        _keyProtector = keyProtector;
        _logger = logger;
        _alpacaSettings = alpacaSettings;
    }

    public async Task<AccountDto> GetAccountAsync(Guid userId)
    {
        // Get user from auth database
        _logger.LogInformation($"Looking up user with ID: {userId}");
        Console.WriteLine($"[ACCOUNTS-DEBUG] Looking up user with ID: {userId}");
        
        var authUser = await _authDb.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(u => u.Id == userId);
            
        if (authUser == null)
        {
            _logger.LogError($"User not found with ID: {userId}");
            Console.WriteLine($"[ACCOUNTS-DEBUG] User not found with ID: {userId}");
            throw new InvalidOperationException("User not found");
        }
        
        Console.WriteLine($"[ACCOUNTS-DEBUG] Found auth user: {authUser.Email}, AlpacaAccountId: {authUser.AlpacaAccountId ?? "NULL"}");
        
        if (string.IsNullOrEmpty(authUser.AlpacaAccountId))
        {
            _logger.LogError($"User {authUser.Email} has no AlpacaAccountId");
            Console.WriteLine($"[ACCOUNTS-DEBUG] User {authUser.Email} has no AlpacaAccountId - throwing exception");
            throw new InvalidOperationException("Alpaca account not linked");
        }
            
        // Use environment variables for API credentials
        var apiKeyId = Environment.GetEnvironmentVariable("ALPACA_API_KEY_ID");
        var apiSecret = Environment.GetEnvironmentVariable("ALPACA_API_SECRET");
        
        if (string.IsNullOrEmpty(apiKeyId) || string.IsNullOrEmpty(apiSecret))
        {
            _logger.LogError("Alpaca API credentials not configured");
            throw new InvalidOperationException("API configuration error");
        }

        var account = await _alpacaClient.GetAccountAsync(apiKeyId, apiSecret, authUser.AlpacaAccountId);

        return new AccountDto(
            account.AccountNumber,
            account.Status,
            account.Cash,
            account.PortfolioValue,
            account.BuyingPower,
            account.PatternDayTrader,
            account.TradingBlocked,
            account.TransfersBlocked,
            account.AccountBlocked
        );
    }

    public async Task<LinkAccountResponse> LinkAccountAsync(Guid userId, LinkAccountRequest request)
    {
        // Validate the API keys by making a test call
        try
        {
            // Check if this is a Broker API account
            // For testing, use the isBrokerApi flag from the request
            var isBrokerApi = request.IsBrokerApi || _alpacaSettings.BaseUrl.Contains("broker-api");
            string? selectedBrokerAccountId = null;
            string accountNumber;
            string accountStatus;
            
            if (isBrokerApi)
            {
                // For Broker API, use provided account ID or get the list of accounts
                if (!string.IsNullOrEmpty(request.BrokerAccountId))
                {
                    selectedBrokerAccountId = request.BrokerAccountId;
                }
                else
                {
                    var brokerAccounts = await _alpacaClient.GetBrokerAccountsAsync(request.ApiKeyId, request.ApiSecret);
                    var activeAccount = brokerAccounts.FirstOrDefault(a => a.Status == "ACTIVE");
                    
                    if (activeAccount == null)
                    {
                        throw new InvalidOperationException("No active broker accounts found");
                    }
                    
                    selectedBrokerAccountId = activeAccount.Id;
                }
                
                // Get the full account details
                var account = await _alpacaClient.GetAccountAsync(request.ApiKeyId, request.ApiSecret, selectedBrokerAccountId);
                accountNumber = account.AccountNumber;
                accountStatus = account.Status;
            }
            else
            {
                // For regular Trading API
                var account = await _alpacaClient.GetAccountAsync(request.ApiKeyId, request.ApiSecret);
                accountNumber = account.AccountNumber;
                accountStatus = account.Status;
            }
            
            // Check if link already exists
            var existingLink = await _db.AlpacaLinks
                .FirstOrDefaultAsync(al => al.UserId == userId && al.Env == request.Env);
                
            if (existingLink != null)
            {
                // Update existing link
                existingLink.AccountId = accountNumber;
                existingLink.ApiKeyId = _keyProtector.Encrypt(request.ApiKeyId);
                existingLink.ApiSecret = _keyProtector.Encrypt(request.ApiSecret);
                existingLink.IsBrokerApi = isBrokerApi;
                existingLink.BrokerAccountId = selectedBrokerAccountId;
            }
            else
            {
                // Create new link
                var alpacaLink = new AlpacaLink
                {
                    Id = Guid.NewGuid(),
                    UserId = userId,
                    AccountId = accountNumber,
                    ApiKeyId = _keyProtector.Encrypt(request.ApiKeyId),
                    ApiSecret = _keyProtector.Encrypt(request.ApiSecret),
                    Env = request.Env,
                    IsBrokerApi = isBrokerApi,
                    BrokerAccountId = selectedBrokerAccountId,
                    CreatedAt = DateTime.UtcNow
                };
                
                _db.AlpacaLinks.Add(alpacaLink);
            }
            
            await _db.SaveChangesAsync();
            
            return new LinkAccountResponse(
                true,
                accountNumber,
                accountStatus
            );
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to link Alpaca account");
            throw new InvalidOperationException("Failed to validate Alpaca API credentials");
        }
    }

    public async Task<UserProfileDto> GetUserProfileAsync(string authSub)
    {
        var user = await _db.Users
            .FirstOrDefaultAsync(u => u.AuthSub == authSub);
            
        if (user == null)
        {
            // Auto-create user on first access
            user = new User
            {
                Id = Guid.NewGuid(),
                AuthSub = authSub,
                Email = $"{authSub}@example.com", // In production, get from JWT claims
                CreatedAt = DateTime.UtcNow
            };
            
            _db.Users.Add(user);
            await _db.SaveChangesAsync();
        }

        return new UserProfileDto(user.AuthSub, user.Email);
    }

    private async Task<AlpacaLink> GetAlpacaLinkAsync(Guid userId)
    {
        var alpacaLink = await _db.AlpacaLinks
            .FirstOrDefaultAsync(al => al.UserId == userId);
            
        if (alpacaLink == null)
        {
            throw new InvalidOperationException("Alpaca account not linked");
        }

        return alpacaLink;
    }
}

public record AccountDto(
    string AccountNumber,
    string Status,
    decimal Cash,
    decimal PortfolioValue,
    decimal BuyingPower,
    bool PatternDayTrader,
    bool TradingBlocked,
    bool TransfersBlocked,
    bool AccountBlocked
);

public record LinkAccountRequest(
    string ApiKeyId,
    string ApiSecret,
    string Env,
    bool IsBrokerApi = false,
    string? BrokerAccountId = null
);

public record LinkAccountResponse(
    bool Linked,
    string AccountId,
    string Status
);

public record UserProfileDto(
    string AuthSub,
    string Email
);