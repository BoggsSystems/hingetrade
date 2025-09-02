using CreatorStudio.Domain.Entities;
using CreatorStudio.Domain.Interfaces;
using Microsoft.Extensions.Logging;
using MediatR;

namespace CreatorStudio.Application.Features.Subscriptions.Commands;

public class UnfollowCreatorCommandHandler : IRequestHandler<UnfollowCreatorCommand, bool>
{
    private readonly IRepository<Subscription> _subscriptionRepository;
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILogger<UnfollowCreatorCommandHandler> _logger;

    public UnfollowCreatorCommandHandler(
        IRepository<Subscription> subscriptionRepository,
        IUnitOfWork unitOfWork,
        ILogger<UnfollowCreatorCommandHandler> logger)
    {
        _subscriptionRepository = subscriptionRepository;
        _unitOfWork = unitOfWork;
        _logger = logger;
    }

    public async Task<bool> Handle(UnfollowCreatorCommand request, CancellationToken cancellationToken)
    {
        try
        {
            var subscription = await _subscriptionRepository.FindFirstAsync(
                s => s.UserId == request.UserId && s.CreatorId == request.CreatorId && s.Status == Domain.Enums.SubscriptionStatus.Active,
                cancellationToken);

            if (subscription == null)
            {
                _logger.LogWarning("No active subscription found for user {UserId} and creator {CreatorId}", request.UserId, request.CreatorId);
                return false;
            }

            // Deactivate the subscription instead of deleting it to preserve history
            subscription.Status = Domain.Enums.SubscriptionStatus.Cancelled;
            subscription.CancelledAt = DateTime.UtcNow;
            subscription.UpdatedAt = DateTime.UtcNow;

            await _subscriptionRepository.UpdateAsync(subscription, cancellationToken);
            await _unitOfWork.SaveChangesAsync(cancellationToken);
            
            _logger.LogInformation("User {UserId} successfully unfollowed creator {CreatorId}", request.UserId, request.CreatorId);
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to unfollow creator {CreatorId} for user {UserId}", request.CreatorId, request.UserId);
            return false;
        }
    }
}