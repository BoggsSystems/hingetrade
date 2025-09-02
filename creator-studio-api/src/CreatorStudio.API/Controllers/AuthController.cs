using MediatR;
using Microsoft.AspNetCore.Mvc;
using CreatorStudio.Application.Features.Auth.Commands;

namespace CreatorStudio.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly IMediator _mediator;

    public AuthController(IMediator mediator)
    {
        _mediator = mediator;
    }

    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] RegisterRequest request)
    {
        try
        {
            var command = new RegisterCommand(
                request.Email,
                request.FirstName,
                request.LastName,
                request.Password
            );

            var response = await _mediator.Send(command);
            
            // Set refresh token as httpOnly cookie
            SetRefreshTokenCookie(response.RefreshToken);

            return Ok(new
            {
                accessToken = response.AccessToken,
                user = response.User
            });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "An error occurred during registration" });
        }
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginRequest request)
    {
        try
        {
            var command = new LoginCommand(request.Email, request.Password);
            var response = await _mediator.Send(command);
            
            // Set refresh token as httpOnly cookie
            SetRefreshTokenCookie(response.RefreshToken);

            return Ok(new
            {
                accessToken = response.AccessToken,
                user = response.User
            });
        }
        catch (UnauthorizedAccessException ex)
        {
            return Unauthorized(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "An error occurred during login" });
        }
    }

    [HttpPost("logout")]
    public IActionResult Logout()
    {
        // Clear refresh token cookie
        Response.Cookies.Delete("refreshToken");
        return Ok(new { message = "Logged out successfully" });
    }

    private void SetRefreshTokenCookie(string refreshToken)
    {
        var cookieOptions = new CookieOptions
        {
            HttpOnly = true,
            Secure = true, // Only over HTTPS in production
            SameSite = SameSiteMode.Strict,
            Expires = DateTime.UtcNow.AddDays(7)
        };

        Response.Cookies.Append("refreshToken", refreshToken, cookieOptions);
    }
}

public record RegisterRequest(
    string Email,
    string FirstName,
    string LastName,
    string Password
);

public record LoginRequest(
    string Email,
    string Password
);