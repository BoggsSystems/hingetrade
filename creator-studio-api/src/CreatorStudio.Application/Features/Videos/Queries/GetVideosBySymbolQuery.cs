using CreatorStudio.Application.DTOs;
using MediatR;

namespace CreatorStudio.Application.Features.Videos.Queries;

public record GetVideosBySymbolQuery(
    string Symbol, 
    int Page, 
    int PageSize, 
    string SortBy = "newest") : IRequest<VideosBySymbolResponse>;

public class VideosBySymbolResponse
{
    public VideoDto[] Videos { get; set; } = Array.Empty<VideoDto>();
    public int Total { get; set; }
    public int Page { get; set; }
    public int PageSize { get; set; }
    public bool HasMore { get; set; }
    public string Symbol { get; set; } = "";
    public string SortBy { get; set; } = "newest";
}