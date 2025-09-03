namespace TraderApi.Data;

public class User
{
    public Guid Id { get; set; }
    public string AuthSub { get; set; } = default!;
    public string Email { get; set; } = default!;
    public DateTime CreatedAt { get; set; }
    
    public ICollection<AlpacaLink> AlpacaLinks { get; set; } = new List<AlpacaLink>();
    public ICollection<Watchlist> Watchlists { get; set; } = new List<Watchlist>();
    public ICollection<Alert> Alerts { get; set; } = new List<Alert>();
    public ICollection<OrderLocalAudit> Orders { get; set; } = new List<OrderLocalAudit>();
    public ICollection<Layout> Layouts { get; set; } = new List<Layout>();
}

public class AlpacaLink
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string AccountId { get; set; } = default!;
    public string ApiKeyId { get; set; } = default!; // Encrypted
    public string ApiSecret { get; set; } = default!; // Encrypted
    public string Env { get; set; } = default!; // paper or live
    public string? BrokerAccountId { get; set; } // Selected broker sub-account ID
    public bool IsBrokerApi { get; set; } // True if using Broker API
    public DateTime CreatedAt { get; set; }
    
    public User User { get; set; } = default!;
}

public class Watchlist
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string Name { get; set; } = default!;
    
    public User User { get; set; } = default!;
    public ICollection<WatchlistSymbol> Symbols { get; set; } = new List<WatchlistSymbol>();
}

public class WatchlistSymbol
{
    public Guid Id { get; set; }
    public Guid WatchlistId { get; set; }
    public string Symbol { get; set; } = default!;
    
    public Watchlist Watchlist { get; set; } = default!;
}

public class Alert
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string Symbol { get; set; } = default!;
    public string Operator { get; set; } = default!; // >, <, >=, <=, crosses_up, crosses_down
    public decimal Threshold { get; set; }
    public bool Active { get; set; }
    public DateTime? LastTriggeredAt { get; set; }
    
    public User User { get; set; } = default!;
}

public class OrderLocalAudit
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string ClientOrderId { get; set; } = default!;
    public string Side { get; set; } = default!; // buy or sell
    public string Symbol { get; set; } = default!;
    public decimal Qty { get; set; }
    public decimal? LimitPrice { get; set; }
    public string Type { get; set; } = default!; // market or limit
    public string TimeInForce { get; set; } = default!; // day, gtc, etc
    public string Status { get; set; } = default!;
    public string? AlpacaOrderId { get; set; }
    public DateTime CreatedAt { get; set; }
    
    public User User { get; set; } = default!;
}

public class Layout
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string Name { get; set; } = default!;
    public bool IsDefault { get; set; }
    public int GridColumns { get; set; } = 12;
    public int RowHeight { get; set; } = 50;
    public string? CompactType { get; set; } // vertical, horizontal, or null
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
    
    public User User { get; set; } = default!;
    public ICollection<Panel> Panels { get; set; } = new List<Panel>();
    public ICollection<LinkGroup> LinkGroups { get; set; } = new List<LinkGroup>();
}

public class Panel
{
    public Guid Id { get; set; }
    public Guid LayoutId { get; set; }
    public string PanelId { get; set; } = default!; // Frontend panel identifier
    public string Type { get; set; } = default!; // watchlist, chart, quote, etc.
    public string? Title { get; set; }
    public int X { get; set; }
    public int Y { get; set; }
    public int W { get; set; }
    public int H { get; set; }
    public int MinW { get; set; } = 2;
    public int MinH { get; set; } = 3;
    public Guid? LinkGroupId { get; set; }
    public string? ConfigJson { get; set; } // Additional panel-specific configuration
    
    public Layout Layout { get; set; } = default!;
    public LinkGroup? LinkGroup { get; set; }
}

public class LinkGroup
{
    public Guid Id { get; set; }
    public Guid LayoutId { get; set; }
    public string GroupId { get; set; } = default!; // Frontend group identifier
    public string Name { get; set; } = default!;
    public string Color { get; set; } = default!;
    public string? Symbol { get; set; } // Current linked symbol
    
    public Layout Layout { get; set; } = default!;
    public ICollection<Panel> Panels { get; set; } = new List<Panel>();
}

// Video-related entities
public class VideoView
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public Guid VideoId { get; set; }
    public TimeSpan WatchDuration { get; set; }
    public int ViewCount { get; set; }
    public DateTime FirstViewedAt { get; set; }
    public DateTime LastViewedAt { get; set; }
    
    public User User { get; set; } = default!;
}

public class VideoInteraction
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public Guid VideoId { get; set; }
    public TraderApi.Features.Videos.VideoInteractionType InteractionType { get; set; }
    public bool Value { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
    
    public User User { get; set; } = default!;
}

public class CreatorFollow
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public Guid CreatorId { get; set; }
    public bool IsFollowing { get; set; }
    public DateTime FollowedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
    
    public User User { get; set; } = default!;
}

public class UserSymbolInterest
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string Symbol { get; set; } = default!;
    public int InterestScore { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
    
    public User User { get; set; } = default!;
}