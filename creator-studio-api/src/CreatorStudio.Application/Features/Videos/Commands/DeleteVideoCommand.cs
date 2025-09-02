using MediatR;

namespace CreatorStudio.Application.Features.Videos.Commands;

public record DeleteVideoCommand(Guid VideoId) : IRequest<bool>;