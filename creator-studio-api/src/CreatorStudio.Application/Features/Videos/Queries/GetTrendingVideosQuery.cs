using CreatorStudio.Application.DTOs;
using MediatR;

namespace CreatorStudio.Application.Features.Videos.Queries;

public record GetTrendingVideosQuery(
    int Page, 
    int PageSize, 
    string? Symbol = null, 
    int Hours = 24) : IRequest<TrendingVideosResponse>;

public class TrendingVideosResponse
{
    public VideoDto[] Videos { get; set; } = Array.Empty<VideoDto>();
    public int Total { get; set; }
    public int Page { get; set; }
    public int PageSize { get; set; }
    public bool HasMore { get; set; }
    public int Hours { get; set; }
}