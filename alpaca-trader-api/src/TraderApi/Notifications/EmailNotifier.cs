namespace TraderApi.Notifications;

public interface IEmailNotifier
{
    Task SendAlertTriggeredAsync(string email, string symbol, string operatorType, decimal threshold, decimal currentPrice);
}

public class EmailNotifier : IEmailNotifier
{
    private readonly ILogger<EmailNotifier> _logger;
    private readonly SmtpSettings _smtpSettings;

    public EmailNotifier(ILogger<EmailNotifier> logger, SmtpSettings smtpSettings)
    {
        _logger = logger;
        _smtpSettings = smtpSettings;
    }

    public Task SendAlertTriggeredAsync(string email, string symbol, string operatorType, decimal threshold, decimal currentPrice)
    {
        // In production, integrate with actual SMTP service
        // For development, just log
        _logger.LogInformation(
            "Alert triggered email: To={Email}, Symbol={Symbol}, Operator={Operator}, Threshold={Threshold}, CurrentPrice={CurrentPrice}",
            email, symbol, operatorType, threshold, currentPrice);

        return Task.CompletedTask;
    }
}