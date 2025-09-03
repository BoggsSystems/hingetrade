using Microsoft.EntityFrameworkCore;
using TraderApi.Data;

namespace TraderApi.Features.Alerts;

public interface IAlertsService
{
    Task<List<AlertDto>> GetAlertsAsync(Guid userId);
    Task<AlertDto> CreateAlertAsync(Guid userId, CreateAlertRequest request);
    Task<bool> UpdateAlertAsync(Guid userId, Guid alertId, UpdateAlertRequest request);
    Task<bool> DeleteAlertAsync(Guid userId, Guid alertId);
    Task<List<Alert>> GetActiveAlertsAsync();
    Task MarkAlertTriggeredAsync(Guid alertId);
}

public class AlertsService : IAlertsService
{
    private readonly AppDbContext _db;
    private readonly ILogger<AlertsService> _logger;

    public AlertsService(AppDbContext db, ILogger<AlertsService> logger)
    {
        _db = db;
        _logger = logger;
    }

    public async Task<List<AlertDto>> GetAlertsAsync(Guid userId)
    {
        var alerts = await _db.Alerts
            .Where(a => a.UserId == userId)
            .OrderBy(a => a.Symbol)
            .ToListAsync();

        return alerts.Select(a => new AlertDto(
            a.Id,
            a.Symbol,
            a.Operator,
            a.Threshold,
            a.Active,
            a.LastTriggeredAt
        )).ToList();
    }

    public async Task<AlertDto> CreateAlertAsync(Guid userId, CreateAlertRequest request)
    {
        var alert = new Alert
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Symbol = request.Symbol.ToUpper(),
            Operator = request.Operator,
            Threshold = request.Threshold,
            Active = request.Active
        };

        _db.Alerts.Add(alert);
        await _db.SaveChangesAsync();

        return new AlertDto(
            alert.Id,
            alert.Symbol,
            alert.Operator,
            alert.Threshold,
            alert.Active,
            alert.LastTriggeredAt
        );
    }

    public async Task<bool> UpdateAlertAsync(Guid userId, Guid alertId, UpdateAlertRequest request)
    {
        var alert = await _db.Alerts
            .FirstOrDefaultAsync(a => a.Id == alertId && a.UserId == userId);
            
        if (alert == null)
        {
            return false;
        }

        if (request.Active.HasValue)
            alert.Active = request.Active.Value;
            
        if (request.Threshold.HasValue)
            alert.Threshold = request.Threshold.Value;
            
        if (!string.IsNullOrEmpty(request.Operator))
            alert.Operator = request.Operator;

        await _db.SaveChangesAsync();
        return true;
    }

    public async Task<bool> DeleteAlertAsync(Guid userId, Guid alertId)
    {
        var alert = await _db.Alerts
            .FirstOrDefaultAsync(a => a.Id == alertId && a.UserId == userId);
            
        if (alert == null)
        {
            return false;
        }

        _db.Alerts.Remove(alert);
        await _db.SaveChangesAsync();
        return true;
    }

    public async Task<List<Alert>> GetActiveAlertsAsync()
    {
        return await _db.Alerts
            .Include(a => a.User)
            .Where(a => a.Active)
            .ToListAsync();
    }

    public async Task MarkAlertTriggeredAsync(Guid alertId)
    {
        var alert = await _db.Alerts.FindAsync(alertId);
        if (alert != null)
        {
            alert.LastTriggeredAt = DateTime.UtcNow;
            await _db.SaveChangesAsync();
        }
    }
}

public record AlertDto(
    Guid Id,
    string Symbol,
    string Operator,
    decimal Threshold,
    bool Active,
    DateTime? LastTriggeredAt
);

public record CreateAlertRequest(
    string Symbol,
    string Operator,
    decimal Threshold,
    bool Active
);

public record UpdateAlertRequest(
    bool? Active,
    decimal? Threshold,
    string? Operator
);