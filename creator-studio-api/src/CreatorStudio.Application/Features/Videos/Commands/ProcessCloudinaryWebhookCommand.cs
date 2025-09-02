using MediatR;

namespace CreatorStudio.Application.Features.Videos.Commands;

public class ProcessCloudinaryWebhookCommand : IRequest<bool>
{
    public string PublicId { get; set; } = string.Empty;
    public string NotificationType { get; set; } = string.Empty;
    public string? Status { get; set; }
    public string? VideoUrl { get; set; }
    public double? Duration { get; set; }
    public int? Width { get; set; }
    public int? Height { get; set; }
    public string? Format { get; set; }
    public string? ResourceType { get; set; }
}