using CreatorStudio.Application.DTOs;
using MediatR;

namespace CreatorStudio.Application.Features.Videos.Commands;

public class UnpublishVideoCommand : IRequest<VideoDto?>
{
    public Guid VideoId { get; }
    public string? Reason { get; }

    public UnpublishVideoCommand(Guid videoId, string? reason = null)
    {
        VideoId = videoId;
        Reason = reason;
    }
}