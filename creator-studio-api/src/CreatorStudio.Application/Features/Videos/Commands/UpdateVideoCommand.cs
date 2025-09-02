using CreatorStudio.Application.DTOs;
using MediatR;

namespace CreatorStudio.Application.Features.Videos.Commands;

public record UpdateVideoCommand(Guid VideoId, UpdateVideoDto UpdateDto) : IRequest<VideoDto?>;