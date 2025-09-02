using CreatorStudio.Application.DTOs;
using MediatR;

namespace CreatorStudio.Application.Features.Subscriptions.Queries;

public record GetUserSubscriptionsQuery(Guid UserId) : IRequest<UserSubscriptionsResponse>;

public class UserSubscriptionsResponse
{
    public SubscriptionDto[] Subscriptions { get; set; } = Array.Empty<SubscriptionDto>();
    public int Total { get; set; }
    public DateTime LastUpdated { get; set; }
}