using MediatR;

namespace CreatorStudio.Application.Features.Videos.Commands;

public class CompleteVideoViewCommand : IRequest<CompleteVideoViewResponse>
{
    public Guid SessionId { get; set; }
    public double FinalWatchTimeSeconds { get; set; }
    public double MaxWatchTimeSeconds { get; set; }
    public bool Completed { get; set; }
    public bool? Liked { get; set; }
    public bool? Shared { get; set; }
}

public class CompleteVideoViewResponse
{
    public bool Success { get; set; }
    public string? ErrorMessage { get; set; }
    public VideoViewSummary? Summary { get; set; }
}

public class VideoViewSummary
{
    public double TotalWatchTimeSeconds { get; set; }
    public double CompletionRate { get; set; }
    public bool WasLiked { get; set; }
    public bool WasShared { get; set; }
    public int UpdatedViewCount { get; set; }
}