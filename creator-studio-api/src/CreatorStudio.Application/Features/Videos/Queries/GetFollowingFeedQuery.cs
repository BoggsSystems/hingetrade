using CreatorStudio.Application.DTOs;
using MediatR;

namespace CreatorStudio.Application.Features.Videos.Queries;

public record GetFollowingFeedQuery(
    Guid UserId, 
    int Page, 
    int PageSize) : IRequest<FollowingFeedResponse>;

public class FollowingFeedResponse
{
    public VideoDto[] Videos { get; set; } = Array.Empty<VideoDto>();
    public int Total { get; set; }
    public int Page { get; set; }
    public int PageSize { get; set; }
    public bool HasMore { get; set; }
    public int FollowingCount { get; set; }
}