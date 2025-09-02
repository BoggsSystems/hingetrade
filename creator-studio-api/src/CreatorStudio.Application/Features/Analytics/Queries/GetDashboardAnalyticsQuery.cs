using CreatorStudio.Application.DTOs;
using MediatR;

namespace CreatorStudio.Application.Features.Analytics.Queries;

public class GetDashboardAnalyticsQuery : IRequest<GetDashboardAnalyticsResponse>
{
    public Guid UserId { get; set; }
    public DateTime? FromDate { get; set; }
    public DateTime? ToDate { get; set; }
}

public class GetDashboardAnalyticsResponse
{
    public bool Success { get; set; }
    public string? ErrorMessage { get; set; }
    public DashboardAnalyticsDto? Analytics { get; set; }
}