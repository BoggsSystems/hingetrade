using MediatR;

namespace CreatorStudio.Application.Features.Videos.Commands;

public class StartVideoViewCommand : IRequest<StartVideoViewResponse>
{
    public Guid VideoId { get; set; }
    public Guid? UserId { get; set; }
    public string? AnonymousId { get; set; }
    public string? IpAddress { get; set; }
    public string? UserAgent { get; set; }
    public string? Country { get; set; }
    public string? City { get; set; }
    public string? DeviceType { get; set; }
    public string? TrafficSource { get; set; }
}

public class StartVideoViewResponse
{
    public Guid SessionId { get; set; }
    public bool Success { get; set; }
    public string? ErrorMessage { get; set; }
    public double? VideoDurationSeconds { get; set; }
}