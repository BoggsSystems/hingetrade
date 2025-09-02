using MediatR;

namespace CreatorStudio.Application.Features.Videos.Commands;

public class UpdateVideoViewCommand : IRequest<UpdateVideoViewResponse>
{
    public Guid SessionId { get; set; }
    public double WatchTimeSeconds { get; set; }
    public double MaxWatchTimeSeconds { get; set; }
    public double WatchPercentage { get; set; }
    public bool IsPaused { get; set; }
}

public class UpdateVideoViewResponse
{
    public bool Success { get; set; }
    public string? ErrorMessage { get; set; }
    public bool SessionExpired { get; set; }
}