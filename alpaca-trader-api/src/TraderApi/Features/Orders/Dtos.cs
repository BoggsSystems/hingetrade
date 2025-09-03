using FluentValidation;

namespace TraderApi.Features.Orders;

public record CreateOrderRequest(
    string ClientOrderId,
    string Symbol,
    string Side,
    string Type,
    decimal Qty,
    decimal? LimitPrice,
    string TimeInForce,
    bool? ExtendedHours = null
);

public class CreateOrderRequestValidator : AbstractValidator<CreateOrderRequest>
{
    public CreateOrderRequestValidator()
    {
        RuleFor(x => x.ClientOrderId)
            .NotEmpty()
            .MaximumLength(100);
            
        RuleFor(x => x.Symbol)
            .NotEmpty()
            .MaximumLength(10)
            .Matches("^[A-Z]+$");
            
        RuleFor(x => x.Side)
            .NotEmpty()
            .Must(x => x == "buy" || x == "sell")
            .WithMessage("Side must be 'buy' or 'sell'");
            
        RuleFor(x => x.Type)
            .NotEmpty()
            .Must(x => x == "market" || x == "limit")
            .WithMessage("Type must be 'market' or 'limit'");
            
        RuleFor(x => x.Qty)
            .GreaterThan(0);
            
        RuleFor(x => x.LimitPrice)
            .GreaterThan(0)
            .When(x => x.Type == "limit")
            .WithMessage("Limit price is required for limit orders");
            
        RuleFor(x => x.TimeInForce)
            .NotEmpty()
            .Must(x => new[] { "day", "gtc", "ioc", "fok" }.Contains(x))
            .WithMessage("TimeInForce must be one of: day, gtc, ioc, fok");
    }
}

public record CreateOrderResponse(
    string AlpacaOrderId,
    string Status,
    DateTime SubmittedAt
);

public record OrderDto(
    string Id,
    string ClientOrderId,
    string Symbol,
    string Side,
    string Type,
    decimal Qty,
    decimal? LimitPrice,
    string TimeInForce,
    string Status,
    DateTime CreatedAt,
    DateTime? FilledAt,
    decimal? FilledAvgPrice
);