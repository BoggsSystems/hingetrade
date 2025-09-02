using CreatorStudio.Application.Features.Videos.Commands;
using MediatR;
using Microsoft.AspNetCore.Mvc;
using System.Text;
using System.Security.Cryptography;

namespace CreatorStudio.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class WebhooksController : ControllerBase
{
    private readonly IMediator _mediator;
    private readonly ILogger<WebhooksController> _logger;
    private readonly IConfiguration _configuration;

    public WebhooksController(IMediator mediator, ILogger<WebhooksController> logger, IConfiguration configuration)
    {
        _mediator = mediator;
        _logger = logger;
        _configuration = configuration;
    }

    /// <summary>
    /// Handle Cloudinary video processing webhook
    /// </summary>
    [HttpPost("cloudinary")]
    public async Task<IActionResult> HandleCloudinaryWebhook()
    {
        try
        {
            // Read the request body
            using var reader = new StreamReader(Request.Body);
            var body = await reader.ReadToEndAsync();
            
            _logger.LogInformation("Received Cloudinary webhook: {Body}", body);

            // Verify webhook signature (optional but recommended)
            if (!ValidateCloudinarySignature(body))
            {
                _logger.LogWarning("Invalid Cloudinary webhook signature");
                return Unauthorized("Invalid signature");
            }

            // Parse the webhook payload
            var webhookData = System.Text.Json.JsonSerializer.Deserialize<CloudinaryWebhookPayload>(body);
            
            if (webhookData == null)
            {
                _logger.LogWarning("Failed to parse Cloudinary webhook payload");
                return BadRequest("Invalid payload format");
            }

            // Process the webhook based on notification type
            switch (webhookData.NotificationType?.ToLower())
            {
                case "upload":
                    await HandleUploadNotification(webhookData);
                    break;
                case "video_processing":
                    await HandleVideoProcessingNotification(webhookData);
                    break;
                default:
                    _logger.LogInformation("Unhandled Cloudinary notification type: {NotificationType}", webhookData.NotificationType);
                    break;
            }

            return Ok();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing Cloudinary webhook");
            return StatusCode(500, "Internal server error");
        }
    }

    private async Task HandleUploadNotification(CloudinaryWebhookPayload payload)
    {
        _logger.LogInformation("Processing upload notification for public_id: {PublicId}", payload.PublicId);
        
        // Find video by Cloudinary public ID and update status
        var command = new ProcessCloudinaryWebhookCommand
        {
            PublicId = payload.PublicId,
            NotificationType = "upload",
            Status = payload.Status,
            VideoUrl = payload.SecureUrl,
            Duration = payload.Duration,
            Width = payload.Width,
            Height = payload.Height,
            Format = payload.Format,
            ResourceType = payload.ResourceType
        };

        await _mediator.Send(command);
    }

    private async Task HandleVideoProcessingNotification(CloudinaryWebhookPayload payload)
    {
        _logger.LogInformation("Processing video processing notification for public_id: {PublicId}, status: {Status}", 
            payload.PublicId, payload.Status);

        var command = new ProcessCloudinaryWebhookCommand
        {
            PublicId = payload.PublicId,
            NotificationType = "video_processing",
            Status = payload.Status,
            VideoUrl = payload.SecureUrl,
            Duration = payload.Duration,
            Width = payload.Width,
            Height = payload.Height,
            Format = payload.Format,
            ResourceType = payload.ResourceType
        };

        await _mediator.Send(command);
    }

    private bool ValidateCloudinarySignature(string body)
    {
        // Get the webhook secret from configuration
        var webhookSecret = _configuration["Cloudinary:WebhookSecret"];
        
        if (string.IsNullOrEmpty(webhookSecret))
        {
            _logger.LogWarning("Cloudinary webhook secret not configured - skipping signature validation");
            return true; // Allow webhook if secret not configured (development mode)
        }

        // Get the signature from headers
        if (!Request.Headers.TryGetValue("X-Cld-Signature", out var signatureHeader))
        {
            _logger.LogWarning("Missing X-Cld-Signature header");
            return false;
        }

        var signature = signatureHeader.ToString();
        
        // Calculate expected signature
        using var hmac = new HMACSHA256(Encoding.UTF8.GetBytes(webhookSecret));
        var expectedSignature = Convert.ToHexString(hmac.ComputeHash(Encoding.UTF8.GetBytes(body))).ToLower();

        var isValid = signature.Equals(expectedSignature, StringComparison.OrdinalIgnoreCase);
        
        if (!isValid)
        {
            _logger.LogWarning("Cloudinary webhook signature mismatch. Expected: {Expected}, Received: {Received}", 
                expectedSignature, signature);
        }

        return isValid;
    }
}

/// <summary>
/// Cloudinary webhook payload structure
/// </summary>
public class CloudinaryWebhookPayload
{
    public string? NotificationType { get; set; }
    public string? PublicId { get; set; }
    public string? Status { get; set; }
    public string? SecureUrl { get; set; }
    public double? Duration { get; set; }
    public int? Width { get; set; }
    public int? Height { get; set; }
    public string? Format { get; set; }
    public string? ResourceType { get; set; }
    public long? Bytes { get; set; }
    public DateTime? CreatedAt { get; set; }
    public string? ETag { get; set; }
}