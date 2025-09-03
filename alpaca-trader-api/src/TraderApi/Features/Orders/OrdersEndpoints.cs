using System.Security.Claims;
using FluentValidation;
using Microsoft.AspNetCore.Http.HttpResults;

namespace TraderApi.Features.Orders;

public static class OrdersEndpoints
{
    public static void MapOrdersEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/orders")
            .RequireAuthorization()
            .WithTags("Orders");

        group.MapGet("/", GetOrders)
            .WithName("GetOrders")
            .WithSummary("Get user's orders")
            .WithDescription("Retrieve orders from Alpaca with optional filtering")
            .Produces<List<OrderDto>>();

        group.MapPost("/", CreateOrder)
            .WithName("CreateOrder")
            .WithSummary("Create a new order")
            .WithDescription("Submit a new order to Alpaca with risk checks")
            .Produces<CreateOrderResponse>(201)
            .ProducesValidationProblem()
            .Produces(400);

        group.MapDelete("/{id}", CancelOrder)
            .WithName("CancelOrder")
            .WithSummary("Cancel an order")
            .WithDescription("Cancel an existing order on Alpaca")
            .Produces(204)
            .Produces(404);
    }

    private static async Task<Ok<List<OrderDto>>> GetOrders(
        IOrdersService ordersService,
        ClaimsPrincipal user,
        string? status = null,
        int? limit = null)
    {
        var userId = GetUserId(user);
        var orders = await ordersService.GetOrdersAsync(userId, status, limit);
        return TypedResults.Ok(orders);
    }

    private static async Task<Results<Created<CreateOrderResponse>, ValidationProblem, BadRequest<ErrorResponse>>> CreateOrder(
        IOrdersService ordersService,
        IValidator<CreateOrderRequest> validator,
        ClaimsPrincipal user,
        CreateOrderRequest request)
    {
        var validationResult = await validator.ValidateAsync(request);
        if (!validationResult.IsValid)
        {
            return TypedResults.ValidationProblem(validationResult.ToDictionary());
        }

        try
        {
            var userId = GetUserId(user);
            var response = await ordersService.CreateOrderAsync(userId, request);
            return TypedResults.Created($"/api/orders/{response.AlpacaOrderId}", response);
        }
        catch (InvalidOperationException ex)
        {
            return TypedResults.BadRequest(new ErrorResponse("ValidationError", ex.Message));
        }
    }

    private static async Task<Results<NoContent, NotFound>> CancelOrder(
        IOrdersService ordersService,
        ClaimsPrincipal user,
        string id)
    {
        var userId = GetUserId(user);
        var success = await ordersService.CancelOrderAsync(userId, id);
        
        return success ? TypedResults.NoContent() : TypedResults.NotFound();
    }

    private static Guid GetUserId(ClaimsPrincipal user)
    {
        var sub = user.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(sub))
            throw new UnauthorizedAccessException("User ID not found in token");
            
        Console.WriteLine($"[ORDERS-ENDPOINT-DEBUG] Found sub claim: {sub}");
        
        // IMPORTANT: We should use the actual GUID from the sub claim, not a hash!
        // The JWT token contains the actual user ID from the auth system
        if (Guid.TryParse(sub, out var actualUserId))
        {
            Console.WriteLine($"[ORDERS-ENDPOINT-DEBUG] Using actual user ID from token: {actualUserId}");
            return actualUserId;
        }
        
        // Fallback to old hash-based approach for backward compatibility
        var hashBasedId = Guid.Parse("00000000-0000-0000-0000-" + sub.GetHashCode().ToString("X").PadLeft(12, '0'));
        Console.WriteLine($"[ORDERS-ENDPOINT-DEBUG] Fallback to hash-based ID: {hashBasedId}");
        return hashBasedId;
    }
}

public record ErrorResponse(string Error, string Details);