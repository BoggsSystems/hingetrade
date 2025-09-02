using System.Security.Claims;
using CreatorStudio.Domain.Entities;

namespace CreatorStudio.Application.Common.Interfaces;

public interface IJwtTokenService
{
    string GenerateAccessToken(User user);
    string GenerateRefreshToken();
    ClaimsPrincipal? ValidateToken(string token);
}