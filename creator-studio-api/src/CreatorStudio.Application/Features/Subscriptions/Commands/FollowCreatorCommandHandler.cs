using CreatorStudio.Domain.Entities;
using CreatorStudio.Domain.Interfaces;
using CreatorStudio.Domain.Enums;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Logging;
using MediatR;

namespace CreatorStudio.Application.Features.Subscriptions.Commands;

public class FollowCreatorCommandHandler : IRequestHandler<FollowCreatorCommand, bool>
{
    private readonly IRepository<Subscription> _subscriptionRepository;
    private readonly UserManager<User> _userManager;
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILogger<FollowCreatorCommandHandler> _logger;

    public FollowCreatorCommandHandler(
        IRepository<Subscription> subscriptionRepository,
        UserManager<User> userManager,
        IUnitOfWork unitOfWork,
        ILogger<FollowCreatorCommandHandler> logger)
    {
        _subscriptionRepository = subscriptionRepository;
        _userManager = userManager;
        _unitOfWork = unitOfWork;
        _logger = logger;
    }

    public async Task<bool> Handle(FollowCreatorCommand request, CancellationToken cancellationToken)
    {
        try
        {
            // Check if user and creator exist
            var user = await _userManager.FindByIdAsync(request.UserId.ToString());
            var creator = await _userManager.FindByIdAsync(request.CreatorId.ToString());
            
            if (user == null)
            {
                throw new ArgumentException($"User with ID {request.UserId} not found");
            }
            
            if (creator == null)
            {
                throw new ArgumentException($"Creator with ID {request.CreatorId} not found");
            }

            // Check if user is trying to follow themselves
            if (request.UserId == request.CreatorId)
            {
                throw new ArgumentException("Users cannot follow themselves");
            }

            // Check if subscription already exists
            var existingSubscription = await _subscriptionRepository.FindFirstAsync(
                s => s.UserId == request.UserId && s.CreatorId == request.CreatorId,
                cancellationToken);

            if (existingSubscription != null)
            {
                if (existingSubscription.Status == Domain.Enums.SubscriptionStatus.Active)
                {
                    _logger.LogWarning("User {UserId} is already following creator {CreatorId}", request.UserId, request.CreatorId);
                    return true; // Already following
                }
                
                // Reactivate existing subscription
                existingSubscription.Status = Domain.Enums.SubscriptionStatus.Active;
                existingSubscription.CancelledAt = null;
                existingSubscription.ExpiresAt = null;
                existingSubscription.UpdatedAt = DateTime.UtcNow;
                
                await _subscriptionRepository.UpdateAsync(existingSubscription, cancellationToken);
            }
            else
            {
                // Create new subscription
                var newSubscription = new Subscription
                {
                    Id = Guid.NewGuid(),
                    UserId = request.UserId,
                    CreatorId = request.CreatorId,
                    Tier = SubscriptionTier.Free, // Default to free following
                    Status = Domain.Enums.SubscriptionStatus.Active,
                    CreatedAt = DateTime.UtcNow
                };

                await _subscriptionRepository.AddAsync(newSubscription, cancellationToken);
            }

            await _unitOfWork.SaveChangesAsync(cancellationToken);
            
            _logger.LogInformation("User {UserId} successfully followed creator {CreatorId}", request.UserId, request.CreatorId);
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to follow creator {CreatorId} for user {UserId}", request.CreatorId, request.UserId);
            return false;
        }
    }
}