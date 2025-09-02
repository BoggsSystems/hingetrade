using CreatorStudio.Application.DTOs;
using MediatR;

namespace CreatorStudio.Application.Features.Videos.Commands;

public record PublishVideoCommand(Guid VideoId) : IRequest<VideoDto?>;