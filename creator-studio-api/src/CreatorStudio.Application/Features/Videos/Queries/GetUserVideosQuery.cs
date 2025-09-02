using CreatorStudio.Application.DTOs;
using MediatR;

namespace CreatorStudio.Application.Features.Videos.Queries;

public record GetUserVideosQuery(Guid UserId) : IRequest<GetUserVideosResponse>;

public class GetUserVideosResponse
{
    public VideoDto[] Videos { get; set; } = Array.Empty<VideoDto>();
    public int Total { get; set; }
}