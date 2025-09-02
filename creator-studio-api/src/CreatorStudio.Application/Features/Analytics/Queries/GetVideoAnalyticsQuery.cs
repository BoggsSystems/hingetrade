using CreatorStudio.Application.DTOs;
using MediatR;

namespace CreatorStudio.Application.Features.Analytics.Queries;

public class GetVideoAnalyticsQuery : IRequest<GetVideoAnalyticsResponse>
{
    public Guid VideoId { get; set; }
    public Guid UserId { get; set; }
    public DateTime? FromDate { get; set; }
    public DateTime? ToDate { get; set; }
}

public class GetVideoAnalyticsResponse
{
    public bool Success { get; set; }
    public string? ErrorMessage { get; set; }
    public VideoAnalyticsDto? Analytics { get; set; }
}