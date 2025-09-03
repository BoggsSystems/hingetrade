namespace TraderApi;

public class AppSettings
{
    public ConnectionStrings ConnectionStrings { get; set; } = new();
    public RedisSettings Redis { get; set; } = new();
    public AuthSettings Auth { get; set; } = new();
    public AlpacaSettings Alpaca { get; set; } = new();
    public KeyProtectionSettings KeyProtection { get; set; } = new();
    public WebhookSettings Webhook { get; set; } = new();
    public NotificationSettings Notifications { get; set; } = new();
    public RateLimitSettings RateLimit { get; set; } = new();
    public RiskSettings Risk { get; set; } = new();
    public AlphaVantageSettings AlphaVantage { get; set; } = new();
}

public class ConnectionStrings
{
    public string Postgres { get; set; } = "Host=localhost;Port=5432;Database=trader;Username=postgres;Password=postgres";
}

public class RedisSettings
{
    public string Connection { get; set; } = "localhost:6379";
}

public class AuthSettings
{
    public string Authority { get; set; } = "";
    public string Audience { get; set; } = "alpaca-trader-api";
}

public class AlpacaSettings
{
    public string Env { get; set; } = "paper";
    public string BaseUrl { get; set; } = "https://paper-api.alpaca.markets";
    public string MarketDataUrl { get; set; } = "wss://stream.data.alpaca.markets/v2/sip";
}

public class KeyProtectionSettings
{
    public string Key { get; set; } = "local-dev-static-key";
}

public class WebhookSettings
{
    public string SigningSecret { get; set; } = "dev-secret";
}

public class NotificationSettings
{
    public SmtpSettings Smtp { get; set; } = new();
}

public class SmtpSettings
{
    public string Host { get; set; } = "localhost";
    public int Port { get; set; } = 2525;
}

public class RateLimitSettings
{
    public int PermitLimit { get; set; } = 60;
    public int WindowInMinutes { get; set; } = 1;
}

public class RiskSettings
{
    public decimal MaxOrderNotional { get; set; } = 25000;
    public int MaxShareQuantity { get; set; } = 5000;
    public List<string> AllowedSymbols { get; set; } = new();  // Empty = allow all
    public List<string> BlockedSymbols { get; set; } = new();   // Symbols to block
    public bool RegularHoursOnly { get; set; } = true;
    public bool RequireTradableAsset { get; set; } = true;      // Must be tradable
    public bool RequireFractionable { get; set; } = false;      // Must support fractional shares
    public decimal MinPrice { get; set; } = 0.01m;              // Minimum stock price
    public decimal MaxPrice { get; set; } = 10000m;             // Maximum stock price
}

public class AlphaVantageSettings
{
    public string ApiKey { get; set; } = "";
    public string BaseUrl { get; set; } = "https://www.alphavantage.co/query";
    public int RateLimitPerMinute { get; set; } = 5;  // Free tier: 5 requests per minute
}