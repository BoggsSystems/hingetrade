using CreatorStudio.Application.DTOs;
using CreatorStudio.Domain.Entities;
using CreatorStudio.Domain.Interfaces;
using Microsoft.AspNetCore.Identity;
using MediatR;

namespace CreatorStudio.Application.Features.Subscriptions.Queries;

public class GetUserSubscriptionsQueryHandler : IRequestHandler<GetUserSubscriptionsQuery, UserSubscriptionsResponse>
{
    private readonly IRepository<Subscription> _subscriptionRepository;
    private readonly IRepository<Video> _videoRepository;
    private readonly UserManager<User> _userManager;

    public GetUserSubscriptionsQueryHandler(
        IRepository<Subscription> subscriptionRepository,
        IRepository<Video> videoRepository,
        UserManager<User> userManager)
    {
        _subscriptionRepository = subscriptionRepository;
        _videoRepository = videoRepository;
        _userManager = userManager;
    }

    public async Task<UserSubscriptionsResponse> Handle(GetUserSubscriptionsQuery request, CancellationToken cancellationToken)
    {
        var subscriptions = await _subscriptionRepository.FindAsync(
            s => s.UserId == request.UserId && s.Status == Domain.Enums.SubscriptionStatus.Active,
            cancellationToken);

        var subscriptionDtos = new List<SubscriptionDto>();

        foreach (var subscription in subscriptions.OrderByDescending(s => s.CreatedAt))
        {
            var creator = await _userManager.FindByIdAsync(subscription.CreatorId.ToString());
            var creatorVideoCount = await _videoRepository.CountAsync(
                v => v.CreatorId == subscription.CreatorId,
                cancellationToken);

            subscriptionDtos.Add(new SubscriptionDto
            {
                Id = subscription.Id,
                UserId = subscription.UserId,
                CreatorId = subscription.CreatorId,
                SubscriptionTier = subscription.Tier,
                StartDate = subscription.CreatedAt,
                EndDate = subscription.ExpiresAt,
                IsActive = subscription.IsActive,
                AutoRenew = false,
                CreatedAt = subscription.CreatedAt,
                UpdatedAt = subscription.UpdatedAt,
                CreatorName = creator?.FullName ?? creator?.Email ?? "Unknown Creator",
                CreatorProfileImageUrl = creator?.ProfileImageUrl,
                CreatorVideoCount = creatorVideoCount
            });
        }

        return new UserSubscriptionsResponse
        {
            Subscriptions = subscriptionDtos.ToArray(),
            Total = subscriptionDtos.Count,
            LastUpdated = DateTime.UtcNow
        };
    }
}