using MediatR;

namespace CreatorStudio.Application.Features.Subscriptions.Commands;

public record FollowCreatorCommand(Guid UserId, Guid CreatorId) : IRequest<bool>;