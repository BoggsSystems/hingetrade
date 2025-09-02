using MediatR;

namespace CreatorStudio.Application.Features.Subscriptions.Queries;

public record GetFollowingStatusQuery(Guid UserId, Guid CreatorId) : IRequest<FollowingStatusResponse>;

public class FollowingStatusResponse
{
    public bool IsFollowing { get; set; }
    public DateTime? FollowedAt { get; set; }
    public string SubscriptionTier { get; set; } = "Free";
    public bool IsActive { get; set; }
}