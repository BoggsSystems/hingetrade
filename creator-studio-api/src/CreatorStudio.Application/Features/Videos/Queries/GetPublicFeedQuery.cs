using CreatorStudio.Application.DTOs;
using MediatR;

namespace CreatorStudio.Application.Features.Videos.Queries;

public record GetPublicFeedQuery(
    int Page, 
    int PageSize, 
    string? Symbol = null, 
    string FeedType = "personalized") : IRequest<PublicFeedResponse>;

public class PublicFeedResponse
{
    public VideoDto[] Videos { get; set; } = Array.Empty<VideoDto>();
    public int Total { get; set; }
    public int Page { get; set; }
    public int PageSize { get; set; }
    public bool HasMore { get; set; }
    public string FeedType { get; set; } = "personalized";
}