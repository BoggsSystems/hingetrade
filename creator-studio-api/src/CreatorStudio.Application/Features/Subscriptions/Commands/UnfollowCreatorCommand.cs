using MediatR;

namespace CreatorStudio.Application.Features.Subscriptions.Commands;

public record UnfollowCreatorCommand(Guid UserId, Guid CreatorId) : IRequest<bool>;