using System.ComponentModel.DataAnnotations;

namespace TraderApi.Features.Auth.Dtos;

public record RegisterRequest(
    [Required][EmailAddress] string Email,
    [Required][MinLength(3)] string Username,
    [Required][MinLength(8)] string Password
);

public record LoginRequest(
    [Required] string EmailOrUsername,
    [Required] string Password
);

public record RefreshTokenRequest(
    [Required] string RefreshToken
);

public record AuthResponse(
    string AccessToken,
    string RefreshToken,
    int ExpiresIn,
    UserDto User
);

public record UserDto(
    Guid Id,
    string Email,
    string Username,
    bool EmailVerified,
    DateTime CreatedAt,
    IEnumerable<string> Roles,
    string KycStatus,
    DateTime? KycSubmittedAt,
    DateTime? KycApprovedAt
);

public record ForgotPasswordRequest(
    [Required][EmailAddress] string Email
);

public record ResetPasswordRequest(
    [Required] string Token,
    [Required][MinLength(8)] string NewPassword
);