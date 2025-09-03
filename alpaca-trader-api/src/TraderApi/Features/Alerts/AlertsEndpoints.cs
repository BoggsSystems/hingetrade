using System.Security.Claims;
using FluentValidation;
using Microsoft.AspNetCore.Http.HttpResults;

namespace TraderApi.Features.Alerts;

public static class AlertsEndpoints
{
    public static void MapAlertsEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/alerts")
            .RequireAuthorization()
            .WithTags("Alerts");

        group.MapGet("/", GetAlerts)
            .WithName("GetAlerts")
            .WithSummary("Get user's price alerts")
            .Produces<List<AlertDto>>();

        group.MapPost("/", CreateAlert)
            .WithName("CreateAlert")
            .WithSummary("Create a new price alert")
            .Produces<AlertDto>(201)
            .ProducesValidationProblem();

        group.MapPatch("/{id}", UpdateAlert)
            .WithName("UpdateAlert")
            .WithSummary("Update an alert")
            .Produces(204)
            .Produces(404);

        group.MapDelete("/{id}", DeleteAlert)
            .WithName("DeleteAlert")
            .WithSummary("Delete an alert")
            .Produces(204)
            .Produces(404);
    }

    private static async Task<Ok<List<AlertDto>>> GetAlerts(
        IAlertsService alertsService,
        ClaimsPrincipal user)
    {
        var userId = GetUserId(user);
        var alerts = await alertsService.GetAlertsAsync(userId);
        return TypedResults.Ok(alerts);
    }

    private static async Task<Results<Created<AlertDto>, ValidationProblem>> CreateAlert(
        IAlertsService alertsService,
        IValidator<CreateAlertRequest> validator,
        ClaimsPrincipal user,
        CreateAlertRequest request)
    {
        var validationResult = await validator.ValidateAsync(request);
        if (!validationResult.IsValid)
        {
            return TypedResults.ValidationProblem(validationResult.ToDictionary());
        }

        var userId = GetUserId(user);
        var alert = await alertsService.CreateAlertAsync(userId, request);
        return TypedResults.Created($"/api/alerts/{alert.Id}", alert);
    }

    private static async Task<Results<NoContent, NotFound>> UpdateAlert(
        IAlertsService alertsService,
        ClaimsPrincipal user,
        Guid id,
        UpdateAlertRequest request)
    {
        var userId = GetUserId(user);
        var success = await alertsService.UpdateAlertAsync(userId, id, request);
        return success ? TypedResults.NoContent() : TypedResults.NotFound();
    }

    private static async Task<Results<NoContent, NotFound>> DeleteAlert(
        IAlertsService alertsService,
        ClaimsPrincipal user,
        Guid id)
    {
        var userId = GetUserId(user);
        var success = await alertsService.DeleteAlertAsync(userId, id);
        return success ? TypedResults.NoContent() : TypedResults.NotFound();
    }

    private static Guid GetUserId(ClaimsPrincipal user)
    {
        var sub = user.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(sub))
            throw new UnauthorizedAccessException("User ID not found in token");
            
        return Guid.Parse("00000000-0000-0000-0000-" + sub.GetHashCode().ToString("X").PadLeft(12, '0'));
    }
}

public class CreateAlertRequestValidator : AbstractValidator<CreateAlertRequest>
{
    private static readonly string[] ValidOperators = { ">", "<", ">=", "<=", "crosses_up", "crosses_down" };

    public CreateAlertRequestValidator()
    {
        RuleFor(x => x.Symbol)
            .NotEmpty()
            .MaximumLength(10)
            .Matches("^[A-Z]+$").WithMessage("Symbol must be uppercase letters only");

        RuleFor(x => x.Operator)
            .NotEmpty()
            .Must(op => ValidOperators.Contains(op))
            .WithMessage($"Operator must be one of: {string.Join(", ", ValidOperators)}");

        RuleFor(x => x.Threshold)
            .GreaterThan(0);
    }
}