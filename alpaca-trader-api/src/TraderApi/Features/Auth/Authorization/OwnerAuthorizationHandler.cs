using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;

namespace TraderApi.Features.Auth.Authorization;

public interface IOwnedResource
{
    int OwnerId { get; }
}

public class OwnerRequirement : IAuthorizationRequirement
{
    public static OwnerRequirement Instance { get; } = new();
}

public class OwnerAuthorizationHandler : AuthorizationHandler<OwnerRequirement, IOwnedResource>
{
    protected override Task HandleRequirementAsync(
        AuthorizationHandlerContext context,
        OwnerRequirement requirement,
        IOwnedResource resource)
    {
        var userIdClaim = context.User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        
        if (int.TryParse(userIdClaim, out var userId) && userId == resource.OwnerId)
        {
            context.Succeed(requirement);
        }
        
        // Admins can access any resource
        if (context.User.IsInRole("Admin"))
        {
            context.Succeed(requirement);
        }
        
        return Task.CompletedTask;
    }
}

public static class AuthorizationExtensions
{
    public static void AddOwnerAuthorization(this IServiceCollection services)
    {
        services.AddSingleton<IAuthorizationHandler, OwnerAuthorizationHandler>();
        services.AddAuthorization(options =>
        {
            options.AddPolicy("OwnerOnly", policy =>
                policy.AddRequirements(OwnerRequirement.Instance));
        });
    }
}