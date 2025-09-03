using Microsoft.EntityFrameworkCore;
using TraderApi.Data;

namespace TraderApi.Features.Watchlists;

public interface IWatchlistsService
{
    Task<List<WatchlistDto>> GetWatchlistsAsync(Guid userId);
    Task<WatchlistDto> CreateWatchlistAsync(Guid userId, CreateWatchlistRequest request);
    Task<bool> AddSymbolAsync(Guid userId, Guid watchlistId, AddSymbolRequest request);
    Task<bool> RemoveSymbolAsync(Guid userId, Guid watchlistId, string symbol);
}

public class WatchlistsService : IWatchlistsService
{
    private readonly AppDbContext _db;
    private readonly ILogger<WatchlistsService> _logger;

    public WatchlistsService(AppDbContext db, ILogger<WatchlistsService> logger)
    {
        _db = db;
        _logger = logger;
    }

    public async Task<List<WatchlistDto>> GetWatchlistsAsync(Guid userId)
    {
        var watchlists = await _db.Watchlists
            .Include(w => w.Symbols)
            .Where(w => w.UserId == userId)
            .ToListAsync();

        return watchlists.Select(w => new WatchlistDto(
            w.Id,
            w.Name,
            w.Symbols.Select(s => s.Symbol).ToList()
        )).ToList();
    }

    public async Task<WatchlistDto> CreateWatchlistAsync(Guid userId, CreateWatchlistRequest request)
    {
        // Check if watchlist name already exists for user
        var exists = await _db.Watchlists
            .AnyAsync(w => w.UserId == userId && w.Name == request.Name);
            
        if (exists)
        {
            throw new InvalidOperationException($"Watchlist '{request.Name}' already exists");
        }

        var watchlist = new Watchlist
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Name = request.Name
        };

        _db.Watchlists.Add(watchlist);
        await _db.SaveChangesAsync();

        return new WatchlistDto(watchlist.Id, watchlist.Name, new List<string>());
    }

    public async Task<bool> AddSymbolAsync(Guid userId, Guid watchlistId, AddSymbolRequest request)
    {
        var watchlist = await _db.Watchlists
            .Include(w => w.Symbols)
            .FirstOrDefaultAsync(w => w.Id == watchlistId && w.UserId == userId);
            
        if (watchlist == null)
        {
            return false;
        }

        // Check if symbol already exists
        var symbolExists = watchlist.Symbols.Any(s => s.Symbol == request.Symbol);
        if (symbolExists)
        {
            throw new InvalidOperationException($"Symbol '{request.Symbol}' already exists in watchlist");
        }

        var watchlistSymbol = new WatchlistSymbol
        {
            Id = Guid.NewGuid(),
            WatchlistId = watchlistId,
            Symbol = request.Symbol
        };

        _db.WatchlistSymbols.Add(watchlistSymbol);
        await _db.SaveChangesAsync();

        return true;
    }

    public async Task<bool> RemoveSymbolAsync(Guid userId, Guid watchlistId, string symbol)
    {
        var watchlist = await _db.Watchlists
            .Include(w => w.Symbols)
            .FirstOrDefaultAsync(w => w.Id == watchlistId && w.UserId == userId);
            
        if (watchlist == null)
        {
            return false;
        }

        var watchlistSymbol = watchlist.Symbols.FirstOrDefault(s => s.Symbol == symbol);
        if (watchlistSymbol == null)
        {
            return false;
        }

        _db.WatchlistSymbols.Remove(watchlistSymbol);
        await _db.SaveChangesAsync();

        return true;
    }
}

public record WatchlistDto(
    Guid Id,
    string Name,
    List<string> Symbols
);

public record CreateWatchlistRequest(string Name);

public record AddSymbolRequest(string Symbol);