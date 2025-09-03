using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.EntityFrameworkCore;
using TraderApi.Alpaca.Models;
using TraderApi.Data;

namespace TraderApi.Features.Webhooks;

public static class AlpacaWebhooksEndpoints
{
    public static void MapWebhooksEndpoints(this IEndpointRouteBuilder app)
    {
        app.MapPost("/api/webhooks/alpaca", HandleAlpacaWebhook)
            .AllowAnonymous()
            .WithName("AlpacaWebhook")
            .WithSummary("Handle Alpaca webhooks")
            .WithDescription("Receive trade_updates and account_updates from Alpaca")
            .WithTags("Webhooks")
            .Produces(200)
            .Produces(401);
    }

    private static async Task<Results<Ok, UnauthorizedHttpResult>> HandleAlpacaWebhook(
        HttpContext context,
        AppDbContext db,
        ILoggerFactory loggerFactory,
        WebhookSettings webhookSettings)
    {
        var logger = loggerFactory.CreateLogger("AlpacaWebhooks");
        
        // Read body
        context.Request.EnableBuffering();
        using var reader = new StreamReader(context.Request.Body, Encoding.UTF8, leaveOpen: true);
        var body = await reader.ReadToEndAsync();
        context.Request.Body.Position = 0;

        // Verify signature
        if (!VerifyWebhookSignature(context.Request, body, webhookSettings.SigningSecret))
        {
            logger.LogWarning("Invalid webhook signature");
            return TypedResults.Unauthorized();
        }

        try
        {
            var payload = JsonSerializer.Deserialize<AlpacaWebhookPayload>(body, new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
            });

            if (payload == null)
            {
                logger.LogWarning("Failed to deserialize webhook payload");
                return TypedResults.Ok();
            }

            logger.LogInformation("Received Alpaca webhook: {Event}", payload.Event);

            // Handle trade updates
            if (payload.Event.StartsWith("trade_") && payload.Order != null)
            {
                await HandleTradeUpdate(db, payload.Order, logger);
            }
            // Handle account updates
            else if (payload.Event.StartsWith("account_") && payload.Account != null)
            {
                await HandleAccountUpdate(db, payload.Account, logger);
            }

            return TypedResults.Ok();
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Error processing webhook");
            return TypedResults.Ok(); // Return OK to prevent retries
        }
    }

    private static bool VerifyWebhookSignature(HttpRequest request, string body, string secret)
    {
        if (!request.Headers.TryGetValue("X-Alpaca-Signature", out var signatureHeader))
        {
            return false;
        }

        var signature = signatureHeader.ToString();
        var expectedSignature = ComputeSignature(body, secret);
        
        return signature == expectedSignature;
    }

    private static string ComputeSignature(string body, string secret)
    {
        using var hmac = new HMACSHA256(Encoding.UTF8.GetBytes(secret));
        var hash = hmac.ComputeHash(Encoding.UTF8.GetBytes(body));
        return Convert.ToBase64String(hash);
    }

    private static async Task HandleTradeUpdate(AppDbContext db, AlpacaOrder order, ILogger logger)
    {
        // Update local order audit
        var orderAudit = await db.Orders
            .FirstOrDefaultAsync(o => o.ClientOrderId == order.ClientOrderId || o.AlpacaOrderId == order.Id);
            
        if (orderAudit != null)
        {
            orderAudit.Status = order.Status;
            
            if (string.IsNullOrEmpty(orderAudit.AlpacaOrderId))
            {
                orderAudit.AlpacaOrderId = order.Id;
            }
            
            await db.SaveChangesAsync();
            
            logger.LogInformation(
                "Updated order {ClientOrderId} status to {Status}",
                orderAudit.ClientOrderId,
                order.Status);
        }
    }

    private static async Task HandleAccountUpdate(AppDbContext db, AlpacaAccount account, ILogger logger)
    {
        // Log account status changes
        logger.LogInformation(
            "Account {AccountNumber} status: {Status}, Trading blocked: {TradingBlocked}",
            account.AccountNumber,
            account.Status,
            account.TradingBlocked);
            
        // In production, you might want to update user status or send notifications
        await Task.CompletedTask;
    }
}