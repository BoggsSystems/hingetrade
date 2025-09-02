using CreatorStudio.Domain.Entities;
using CreatorStudio.Domain.Interfaces;
using MediatR;

namespace CreatorStudio.Application.Features.Subscriptions.Queries;

public class GetFollowingStatusQueryHandler : IRequestHandler<GetFollowingStatusQuery, FollowingStatusResponse>
{
    private readonly IRepository<Subscription> _subscriptionRepository;

    public GetFollowingStatusQueryHandler(IRepository<Subscription> subscriptionRepository)
    {
        _subscriptionRepository = subscriptionRepository;
    }

    public async Task<FollowingStatusResponse> Handle(GetFollowingStatusQuery request, CancellationToken cancellationToken)
    {
        var subscription = await _subscriptionRepository.FindFirstAsync(
            s => s.UserId == request.UserId && s.CreatorId == request.CreatorId,
            cancellationToken);

        if (subscription == null)
        {
            return new FollowingStatusResponse
            {
                IsFollowing = false,
                IsActive = false
            };
        }

        return new FollowingStatusResponse
        {
            IsFollowing = subscription.IsActive,
            FollowedAt = subscription.CreatedAt,
            SubscriptionTier = subscription.Tier.ToString(),
            IsActive = subscription.IsActive
        };
    }
}