using Microsoft.EntityFrameworkCore;
using TraderApi.Alpaca;
using TraderApi.Alpaca.Models;
using TraderApi.Data;
using TraderApi.Features.Orders.Risk;
using TraderApi.Security;

namespace TraderApi.Features.Orders;

public interface IOrdersService
{
    Task<List<OrderDto>> GetOrdersAsync(Guid userId, string? status, int? limit);
    Task<CreateOrderResponse> CreateOrderAsync(Guid userId, CreateOrderRequest request);
    Task<bool> CancelOrderAsync(Guid userId, string orderId);
}

public class OrdersService : IOrdersService
{
    private readonly AppDbContext _db;
    private readonly IAlpacaClient _alpacaClient;
    private readonly IRiskService _riskService;
    private readonly IKeyProtector _keyProtector;
    private readonly ILogger<OrdersService> _logger;

    public OrdersService(
        AppDbContext db,
        IAlpacaClient alpacaClient,
        IRiskService riskService,
        IKeyProtector keyProtector,
        ILogger<OrdersService> logger)
    {
        _db = db;
        _alpacaClient = alpacaClient;
        _riskService = riskService;
        _keyProtector = keyProtector;
        _logger = logger;
    }

    public async Task<List<OrderDto>> GetOrdersAsync(Guid userId, string? status, int? limit)
    {
        var alpacaLink = await GetAlpacaLinkAsync(userId);
        var apiKeyId = _keyProtector.Decrypt(alpacaLink.ApiKeyId);
        var apiSecret = _keyProtector.Decrypt(alpacaLink.ApiSecret);

        var orders = await _alpacaClient.GetOrdersAsync(apiKeyId, apiSecret, status, limit, alpacaLink.BrokerAccountId);

        return orders.Select(o => new OrderDto(
            o.Id,
            o.ClientOrderId,
            o.Symbol,
            o.Side,
            o.Type,
            o.Qty,
            o.LimitPrice,
            o.TimeInForce,
            o.Status,
            o.CreatedAt,
            o.FilledAt,
            o.FilledAvgPrice
        )).ToList();
    }

    public async Task<CreateOrderResponse> CreateOrderAsync(Guid userId, CreateOrderRequest request)
    {
        // Check for idempotency
        var existingOrder = await _db.Orders
            .FirstOrDefaultAsync(o => o.ClientOrderId == request.ClientOrderId);
            
        if (existingOrder != null)
        {
            throw new InvalidOperationException($"Order with client_order_id '{request.ClientOrderId}' already exists");
        }

        var alpacaLink = await GetAlpacaLinkAsync(userId);
        var apiKeyId = _keyProtector.Decrypt(alpacaLink.ApiKeyId);
        var apiSecret = _keyProtector.Decrypt(alpacaLink.ApiSecret);

        // Run risk checks
        var violations = await _riskService.ValidateOrderAsync(request, apiKeyId, apiSecret);
        if (violations.Any())
        {
            var messages = string.Join("; ", violations.Select(v => v.Message));
            throw new InvalidOperationException($"Risk check failed: {messages}");
        }

        // Create order audit record
        var orderAudit = new OrderLocalAudit
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            ClientOrderId = request.ClientOrderId,
            Side = request.Side,
            Symbol = request.Symbol,
            Qty = request.Qty,
            LimitPrice = request.LimitPrice,
            Type = request.Type,
            TimeInForce = request.TimeInForce,
            Status = "pending",
            CreatedAt = DateTime.UtcNow
        };

        _db.Orders.Add(orderAudit);
        await _db.SaveChangesAsync();

        try
        {
            // Submit to Alpaca
            var alpacaRequest = new AlpacaOrderRequest
            {
                Symbol = request.Symbol,
                Qty = request.Qty,
                Side = request.Side,
                Type = request.Type,
                TimeInForce = request.TimeInForce,
                LimitPrice = request.LimitPrice,
                ClientOrderId = request.ClientOrderId,
                ExtendedHours = request.ExtendedHours
            };

            var alpacaOrder = await _alpacaClient.CreateOrderAsync(apiKeyId, apiSecret, alpacaRequest, alpacaLink.BrokerAccountId);

            // Update audit record
            orderAudit.AlpacaOrderId = alpacaOrder.Id;
            orderAudit.Status = alpacaOrder.Status;
            await _db.SaveChangesAsync();

            return new CreateOrderResponse(
                alpacaOrder.Id,
                alpacaOrder.Status,
                alpacaOrder.SubmittedAt ?? DateTime.UtcNow
            );
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to create order");
            orderAudit.Status = "failed";
            await _db.SaveChangesAsync();
            throw;
        }
    }

    public async Task<bool> CancelOrderAsync(Guid userId, string orderId)
    {
        var alpacaLink = await GetAlpacaLinkAsync(userId);
        var apiKeyId = _keyProtector.Decrypt(alpacaLink.ApiKeyId);
        var apiSecret = _keyProtector.Decrypt(alpacaLink.ApiSecret);

        var success = await _alpacaClient.CancelOrderAsync(apiKeyId, apiSecret, orderId, alpacaLink.BrokerAccountId);

        if (success)
        {
            // Update local audit if we have it
            var orderAudit = await _db.Orders
                .FirstOrDefaultAsync(o => o.AlpacaOrderId == orderId);
                
            if (orderAudit != null)
            {
                orderAudit.Status = "canceled";
                await _db.SaveChangesAsync();
            }
        }

        return success;
    }

    private async Task<AlpacaLink> GetAlpacaLinkAsync(Guid userId)
    {
        Console.WriteLine($"[ORDERS-DEBUG] Looking for AlpacaLink for userId: {userId}");
        
        var alpacaLink = await _db.AlpacaLinks
            .FirstOrDefaultAsync(al => al.UserId == userId);
            
        if (alpacaLink == null)
        {
            Console.WriteLine($"[ORDERS-DEBUG] No AlpacaLink found for userId: {userId}");
            
            // Let's check if we have a User record
            var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == userId);
            if (user == null)
            {
                Console.WriteLine($"[ORDERS-DEBUG] No User record found for userId: {userId}");
            }
            else
            {
                Console.WriteLine($"[ORDERS-DEBUG] Found User record for {user.Email}, but no AlpacaLink");
            }
            
            // Let's check all AlpacaLinks to see what we have
            var allLinks = await _db.AlpacaLinks.ToListAsync();
            Console.WriteLine($"[ORDERS-DEBUG] Total AlpacaLinks in database: {allLinks.Count}");
            foreach (var link in allLinks)
            {
                Console.WriteLine($"[ORDERS-DEBUG] AlpacaLink: UserId={link.UserId}, AccountId={link.AccountId}, BrokerAccountId={link.BrokerAccountId}");
            }
            
            throw new InvalidOperationException("Alpaca account not linked");
        }

        Console.WriteLine($"[ORDERS-DEBUG] Found AlpacaLink for userId: {userId}, AccountId: {alpacaLink.AccountId}, BrokerAccountId: {alpacaLink.BrokerAccountId}");
        return alpacaLink;
    }
}