using Microsoft.EntityFrameworkCore;
using TraderApi.Data;
using System.Text.Json;
using System.Linq;

namespace TraderApi.Features.Layouts;

public interface ILayoutsService
{
    Task<List<LayoutDto>> GetLayoutsAsync(Guid userId);
    Task<LayoutDto> GetLayoutAsync(Guid userId, Guid layoutId);
    Task<LayoutDto> CreateLayoutAsync(Guid userId, CreateLayoutRequest request);
    Task<LayoutDto> UpdateLayoutAsync(Guid userId, Guid layoutId, UpdateLayoutRequest request);
    Task<bool> DeleteLayoutAsync(Guid userId, Guid layoutId);
    Task<LayoutDto> SetDefaultLayoutAsync(Guid userId, Guid layoutId);
}

public class LayoutsService : ILayoutsService
{
    private readonly AppDbContext _db;
    private readonly ILogger<LayoutsService> _logger;

    public LayoutsService(AppDbContext db, ILogger<LayoutsService> logger)
    {
        _db = db;
        _logger = logger;
    }

    public async Task<List<LayoutDto>> GetLayoutsAsync(Guid userId)
    {
        var layouts = await _db.Layouts
            .Include(l => l.Panels)
            .ThenInclude(p => p.LinkGroup)
            .Include(l => l.LinkGroups)
            .Where(l => l.UserId == userId)
            .OrderByDescending(l => l.IsDefault)
            .ThenByDescending(l => l.UpdatedAt)
            .ToListAsync();

        return layouts.Select(MapToDto).ToList();
    }

    public async Task<LayoutDto> GetLayoutAsync(Guid userId, Guid layoutId)
    {
        var layout = await _db.Layouts
            .Include(l => l.Panels)
            .ThenInclude(p => p.LinkGroup)
            .Include(l => l.LinkGroups)
            .FirstOrDefaultAsync(l => l.Id == layoutId && l.UserId == userId);

        if (layout == null)
        {
            throw new InvalidOperationException("Layout not found");
        }

        return MapToDto(layout);
    }

    public async Task<LayoutDto> CreateLayoutAsync(Guid userId, CreateLayoutRequest request)
    {
        // Check if layout name already exists for user
        var exists = await _db.Layouts
            .AnyAsync(l => l.UserId == userId && l.Name == request.Name);
            
        if (exists)
        {
            throw new InvalidOperationException($"Layout '{request.Name}' already exists");
        }

        // If this is the first layout or requested as default, make it default
        var hasLayouts = await _db.Layouts.AnyAsync(l => l.UserId == userId);
        var isDefault = !hasLayouts || request.IsDefault;

        // If setting as default, unset any existing default
        if (isDefault && hasLayouts)
        {
            await _db.Layouts
                .Where(l => l.UserId == userId && l.IsDefault)
                .ExecuteUpdateAsync(s => s.SetProperty(l => l.IsDefault, false));
        }

        var layout = new Layout
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Name = request.Name,
            IsDefault = isDefault,
            GridColumns = request.GridConfig?.Columns ?? 12,
            RowHeight = request.GridConfig?.RowHeight ?? 50,
            CompactType = request.GridConfig?.CompactType,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        // Add panels
        if (request.Panels != null)
        {
            foreach (var panelRequest in request.Panels)
            {
                var panel = new Panel
                {
                    Id = Guid.NewGuid(),
                    LayoutId = layout.Id,
                    PanelId = panelRequest.Id,
                    Type = panelRequest.Type,
                    Title = panelRequest.Title,
                    X = panelRequest.Position.X,
                    Y = panelRequest.Position.Y,
                    W = panelRequest.Position.W,
                    H = panelRequest.Position.H,
                    MinW = panelRequest.Position.MinW,
                    MinH = panelRequest.Position.MinH,
                    ConfigJson = panelRequest.Config != null ? JsonSerializer.Serialize(panelRequest.Config) : null
                };
                layout.Panels.Add(panel);
            }
        }

        // Add link groups
        if (request.LinkGroups != null)
        {
            foreach (var groupRequest in request.LinkGroups)
            {
                var linkGroup = new LinkGroup
                {
                    Id = Guid.NewGuid(),
                    LayoutId = layout.Id,
                    GroupId = groupRequest.Id,
                    Name = groupRequest.Name,
                    Color = groupRequest.Color,
                    Symbol = groupRequest.Symbol
                };
                layout.LinkGroups.Add(linkGroup);

                // Update panels with link group associations
                if (groupRequest.PanelIds != null)
                {
                    foreach (var panelId in groupRequest.PanelIds)
                    {
                        var panel = layout.Panels.FirstOrDefault(p => p.PanelId == panelId);
                        if (panel != null)
                        {
                            panel.LinkGroupId = linkGroup.Id;
                        }
                    }
                }
            }
        }

        _db.Layouts.Add(layout);
        await _db.SaveChangesAsync();

        _logger.LogInformation("Created layout {LayoutId} for user {UserId}", layout.Id, userId);

        return MapToDto(layout);
    }

    public async Task<LayoutDto> UpdateLayoutAsync(Guid userId, Guid layoutId, UpdateLayoutRequest request)
    {
        _logger.LogInformation("Starting UpdateLayoutAsync for layout {LayoutId}, user {UserId}. Navigation properties fix is ACTIVE.", layoutId, userId);
        
        var layout = await _db.Layouts
            .Include(l => l.Panels)
                .ThenInclude(p => p.LinkGroup)
            .Include(l => l.LinkGroups)
            .FirstOrDefaultAsync(l => l.Id == layoutId && l.UserId == userId);
        
        _logger.LogInformation("Layout loaded: {LayoutFound}, Panels: {PanelCount}, LinkGroups: {LinkGroupCount}", 
            layout != null, layout?.Panels?.Count ?? 0, layout?.LinkGroups?.Count ?? 0);

        if (layout == null)
        {
            throw new InvalidOperationException("Layout not found");
        }

        // Update basic properties if provided
        if (!string.IsNullOrEmpty(request.Name))
        {
            // Check if new name conflicts with existing
            var nameExists = await _db.Layouts
                .AnyAsync(l => l.UserId == userId && l.Id != layoutId && l.Name == request.Name);
            
            if (nameExists)
            {
                throw new InvalidOperationException($"Layout '{request.Name}' already exists");
            }

            layout.Name = request.Name;
        }

        if (request.GridConfig != null)
        {
            layout.GridColumns = request.GridConfig.Columns;
            layout.RowHeight = request.GridConfig.RowHeight;
            layout.CompactType = request.GridConfig.CompactType ?? layout.CompactType;
        }

        // Update panels if provided
        if (request.Panels != null)
        {
            _logger.LogInformation("Updating panels. Request has {RequestPanelCount} panels", request.Panels.Count);
            
            // Log incoming panel data
            foreach (var requestPanel in request.Panels)
            {
                _logger.LogInformation("Incoming panel: Id={PanelId}, Type={Type}, Position=({X},{Y},{W},{H})", 
                    requestPanel.Id ?? "NULL", requestPanel.Type, 
                    requestPanel.Position.X, requestPanel.Position.Y, 
                    requestPanel.Position.W, requestPanel.Position.H);
            }
            
            // Log existing panels
            foreach (var p in layout.Panels)
            {
                _logger.LogInformation("Existing panel in layout: PanelId={PanelId}, DbId={DbId}", p.PanelId, p.Id);
            }
            
            // Create a dictionary of existing panels by PanelId
            var existingPanels = layout.Panels.ToDictionary(p => p.PanelId);
            
            // Create a set of panel IDs from the request
            var requestPanelIds = request.Panels.Select(p => p.Id).ToHashSet();
            
            // Remove panels that are no longer in the request
            var panelsToRemove = layout.Panels.Where(p => !requestPanelIds.Contains(p.PanelId)).ToList();
            foreach (var panel in panelsToRemove)
            {
                layout.Panels.Remove(panel);
                _db.Panels.Remove(panel);
            }
            
            // Update existing panels or add new ones
            foreach (var panelRequest in request.Panels)
            {
                var panelId = panelRequest.Id;
                if (string.IsNullOrEmpty(panelId))
                {
                    // Generate a new panel ID if one isn't provided
                    panelId = $"panel-{DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()}";
                    _logger.LogInformation("Generated new panel ID: {PanelId} for panel without ID", panelId);
                }
                
                if (existingPanels.TryGetValue(panelId, out var existingPanel))
                {
                    _logger.LogInformation("Updating existing panel {PanelId} (DB ID: {DbId})", panelId, existingPanel.Id);
                    // Update existing panel
                    existingPanel.Type = panelRequest.Type;
                    existingPanel.Title = panelRequest.Title;
                    existingPanel.X = panelRequest.Position.X;
                    existingPanel.Y = panelRequest.Position.Y;
                    existingPanel.W = panelRequest.Position.W;
                    existingPanel.H = panelRequest.Position.H;
                    existingPanel.MinW = panelRequest.Position.MinW;
                    existingPanel.MinH = panelRequest.Position.MinH;
                    existingPanel.ConfigJson = panelRequest.Config != null ? JsonSerializer.Serialize(panelRequest.Config) : null;
                    
                    _logger.LogInformation("Panel {PanelId} updated with position: X={X}, Y={Y}, W={W}, H={H}", 
                        panelId, existingPanel.X, existingPanel.Y, existingPanel.W, existingPanel.H);
                }
                else
                {
                    _logger.LogInformation("Adding new panel {PanelId} to layout", panelId);
                    // Add new panel
                    var panel = new Panel
                    {
                        Id = Guid.NewGuid(),
                        LayoutId = layout.Id,
                        PanelId = panelId,
                        Type = panelRequest.Type,
                        Title = panelRequest.Title,
                        X = panelRequest.Position.X,
                        Y = panelRequest.Position.Y,
                        W = panelRequest.Position.W,
                        H = panelRequest.Position.H,
                        MinW = panelRequest.Position.MinW,
                        MinH = panelRequest.Position.MinH,
                        ConfigJson = panelRequest.Config != null ? JsonSerializer.Serialize(panelRequest.Config) : null
                    };
                    layout.Panels.Add(panel);
                    // Explicitly mark the panel as Added to ensure EF knows to INSERT it
                    _db.Entry(panel).State = EntityState.Added;
                    _logger.LogInformation("Added new panel with DB ID: {DbId}, PanelId: {PanelId}, State: {State}", 
                        panel.Id, panel.PanelId, _db.Entry(panel).State);
                }
            }
        }

        // Update link groups if provided
        if (request.LinkGroups != null)
        {
            _logger.LogInformation("Updating link groups. Request has {RequestLinkGroupCount} link groups", request.LinkGroups.Count);
            // Create a dictionary of existing link groups by GroupId
            var existingGroups = layout.LinkGroups.ToDictionary(g => g.GroupId);
            
            // Create a set of group IDs from the request
            var requestGroupIds = request.LinkGroups.Select(g => g.Id).ToHashSet();
            
            // Remove link groups that are no longer in the request
            var groupsToRemove = layout.LinkGroups.Where(g => !requestGroupIds.Contains(g.GroupId)).ToList();
            foreach (var group in groupsToRemove)
            {
                layout.LinkGroups.Remove(group);
                _db.LinkGroups.Remove(group);
            }
            
            // Update existing groups or add new ones
            foreach (var groupRequest in request.LinkGroups)
            {
                LinkGroup linkGroup;
                if (existingGroups.TryGetValue(groupRequest.Id, out var existingGroup))
                {
                    // Update existing group
                    existingGroup.Name = groupRequest.Name;
                    existingGroup.Color = groupRequest.Color;
                    existingGroup.Symbol = groupRequest.Symbol;
                    linkGroup = existingGroup;
                }
                else
                {
                    // Add new group
                    linkGroup = new LinkGroup
                    {
                        Id = Guid.NewGuid(),
                        LayoutId = layout.Id,
                        GroupId = groupRequest.Id,
                        Name = groupRequest.Name,
                        Color = groupRequest.Color,
                        Symbol = groupRequest.Symbol
                    };
                    layout.LinkGroups.Add(linkGroup);
                    // Explicitly mark as Added
                    _db.Entry(linkGroup).State = EntityState.Added;
                }

                // Update panels with link group associations
                if (groupRequest.PanelIds != null)
                {
                    foreach (var panelId in groupRequest.PanelIds)
                    {
                        var panel = layout.Panels.FirstOrDefault(p => p.PanelId == panelId);
                        if (panel != null)
                        {
                            panel.LinkGroupId = linkGroup.Id;
                        }
                    }
                }
            }
        }

        layout.UpdatedAt = DateTime.UtcNow;
        
        try
        {
            _logger.LogInformation("Saving changes. Layout has {PanelCount} panels and {LinkGroupCount} link groups before save", 
                layout.Panels.Count, layout.LinkGroups.Count);
            
            await _db.SaveChangesAsync();
            
            _logger.LogInformation("Successfully saved layout {LayoutId} for user {UserId}. Panels after save: {PanelCount}, LinkGroups: {LinkGroupCount}", 
                layoutId, userId, layout.Panels.Count, layout.LinkGroups.Count);
        }
        catch (DbUpdateConcurrencyException ex)
        {
            _logger.LogError(ex, "Concurrency error updating layout {LayoutId}. This often happens when panels are being updated that don't exist in the database.", layoutId);
            
            // Instead of trying to reload and save again, we need to handle this more carefully
            // The concurrency exception usually means we're trying to update a panel that doesn't exist
            // This can happen if the panel IDs in the database don't match what's expected
            
            // Log the current state for debugging
            _logger.LogError("Layout state at time of error - Panels in memory: {PanelCount}, LinkGroups: {LinkGroupCount}", 
                layout.Panels.Count, layout.LinkGroups.Count);
            
            // Re-throw as a more user-friendly error
            throw new InvalidOperationException("Unable to update layout. The layout may have been modified by another process or contains invalid panel references.", ex);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unexpected error updating layout {LayoutId}. Exception type: {ExceptionType}, Message: {Message}", 
                layoutId, ex.GetType().Name, ex.Message);
            throw;
        }

        // The layout already has all navigation properties loaded from the initial query
        // No need to reload them - just map to DTO
        _logger.LogInformation("Mapping layout to DTO. Navigation properties should already be loaded.");
        
        try
        {
            var dto = MapToDto(layout);
            _logger.LogInformation("Successfully mapped layout {LayoutId} to DTO. DTO has {PanelCount} panels and {LinkGroupCount} link groups", 
                layoutId, dto.Panels.Count, dto.LinkGroups.Count);
            return dto;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error mapping layout to DTO. Layout ID: {LayoutId}, Exception: {ExceptionType}", 
                layoutId, ex.GetType().Name);
            throw;
        }
    }

    public async Task<bool> DeleteLayoutAsync(Guid userId, Guid layoutId)
    {
        var layout = await _db.Layouts
            .FirstOrDefaultAsync(l => l.Id == layoutId && l.UserId == userId);

        if (layout == null)
        {
            return false;
        }

        // Don't delete if it's the only layout
        var layoutCount = await _db.Layouts.CountAsync(l => l.UserId == userId);
        if (layoutCount == 1)
        {
            throw new InvalidOperationException("Cannot delete the last layout");
        }

        // If deleting default layout, make another one default
        if (layout.IsDefault)
        {
            var nextDefault = await _db.Layouts
                .Where(l => l.UserId == userId && l.Id != layoutId)
                .OrderByDescending(l => l.UpdatedAt)
                .FirstAsync();
            
            nextDefault.IsDefault = true;
        }

        _db.Layouts.Remove(layout);
        await _db.SaveChangesAsync();

        _logger.LogInformation("Deleted layout {LayoutId} for user {UserId}", layoutId, userId);

        return true;
    }

    public async Task<LayoutDto> SetDefaultLayoutAsync(Guid userId, Guid layoutId)
    {
        var layout = await _db.Layouts
            .FirstOrDefaultAsync(l => l.Id == layoutId && l.UserId == userId);

        if (layout == null)
        {
            throw new InvalidOperationException("Layout not found");
        }

        if (!layout.IsDefault)
        {
            // Unset any existing default
            await _db.Layouts
                .Where(l => l.UserId == userId && l.IsDefault)
                .ExecuteUpdateAsync(s => s.SetProperty(l => l.IsDefault, false));

            // Set new default
            layout.IsDefault = true;
            layout.UpdatedAt = DateTime.UtcNow;
            await _db.SaveChangesAsync();

            _logger.LogInformation("Set layout {LayoutId} as default for user {UserId}", layoutId, userId);
        }

        return await GetLayoutAsync(userId, layoutId);
    }

    private static LayoutDto MapToDto(Layout layout)
    {
        var panels = layout.Panels.Select(p => 
        {
            try
            {
                var linkGroupId = p.LinkGroupId.HasValue 
                    ? layout.LinkGroups.FirstOrDefault(lg => lg.Id == p.LinkGroupId.Value)?.GroupId 
                    : null;
                    
                var panelDto = new PanelDto
                {
                    Id = p.PanelId,
                    Type = p.Type,
                    Title = p.Title,
                    Position = new PositionDto
                    {
                        X = p.X,
                        Y = p.Y,
                        W = p.W,
                        H = p.H,
                        MinW = p.MinW,
                        MinH = p.MinH
                    },
                    LinkGroupId = linkGroupId,
                    Config = string.IsNullOrEmpty(p.ConfigJson) ? null : JsonDocument.Parse(p.ConfigJson).RootElement
                };
                
                Console.WriteLine($"MapToDto - Panel {p.PanelId}: Position=({p.X},{p.Y},{p.W},{p.H}) -> DTO Position=({panelDto.Position.X},{panelDto.Position.Y},{panelDto.Position.W},{panelDto.Position.H})");
                
                return panelDto;
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException($"Error mapping panel {p.PanelId} to DTO. LinkGroupId: {p.LinkGroupId}, Type: {p.Type}", ex);
            }
        }).ToList();

        var linkGroups = layout.LinkGroups.Select(lg => new LinkGroupDto
        {
            Id = lg.GroupId,
            Name = lg.Name,
            Color = lg.Color,
            Symbol = lg.Symbol,
            PanelIds = layout.Panels
                .Where(p => p.LinkGroupId == lg.Id)
                .Select(p => p.PanelId)
                .ToList()
        }).ToList();

        return new LayoutDto
        {
            Id = layout.Id.ToString(),
            Name = layout.Name,
            IsDefault = layout.IsDefault,
            GridConfig = new GridConfigDto
            {
                Columns = layout.GridColumns,
                RowHeight = layout.RowHeight,
                CompactType = layout.CompactType
            },
            Panels = panels,
            LinkGroups = linkGroups,
            CreatedAt = layout.CreatedAt,
            UpdatedAt = layout.UpdatedAt
        };
    }
}

// DTOs
public record LayoutDto
{
    public string Id { get; init; } = default!;
    public string Name { get; init; } = default!;
    public bool IsDefault { get; init; }
    public GridConfigDto GridConfig { get; init; } = default!;
    public List<PanelDto> Panels { get; init; } = new();
    public List<LinkGroupDto> LinkGroups { get; init; } = new();
    public DateTime CreatedAt { get; init; }
    public DateTime UpdatedAt { get; init; }
}

public record GridConfigDto
{
    public int Columns { get; init; }
    public int RowHeight { get; init; }
    public string? CompactType { get; init; }
}

public record PanelDto
{
    public string Id { get; init; } = default!;
    public string Type { get; init; } = default!;
    public string? Title { get; init; }
    public PositionDto Position { get; init; } = default!;
    public string? LinkGroupId { get; init; }
    public JsonElement? Config { get; init; }
}

public record PositionDto
{
    public int X { get; init; }
    public int Y { get; init; }
    public int W { get; init; }
    public int H { get; init; }
    public int MinW { get; init; }
    public int MinH { get; init; }
}

public record LinkGroupDto
{
    public string Id { get; init; } = default!;
    public string Name { get; init; } = default!;
    public string Color { get; init; } = default!;
    public string? Symbol { get; init; }
    public List<string> PanelIds { get; init; } = new();
}

// Request models
public record CreateLayoutRequest
{
    public string Name { get; init; } = default!;
    public bool IsDefault { get; init; }
    public GridConfigDto? GridConfig { get; init; }
    public List<PanelDto>? Panels { get; init; }
    public List<LinkGroupDto>? LinkGroups { get; init; }
}

public record UpdateLayoutRequest
{
    public string? Name { get; init; }
    public GridConfigDto? GridConfig { get; init; }
    public List<PanelDto>? Panels { get; init; }
    public List<LinkGroupDto>? LinkGroups { get; init; }
}