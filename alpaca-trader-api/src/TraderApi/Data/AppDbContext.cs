using Microsoft.EntityFrameworkCore;
using TraderApi.Data.Entities;

namespace TraderApi.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<User> Users => Set<User>();
    public DbSet<AlpacaLink> AlpacaLinks => Set<AlpacaLink>();
    public DbSet<Watchlist> Watchlists => Set<Watchlist>();
    public DbSet<WatchlistSymbol> WatchlistSymbols => Set<WatchlistSymbol>();
    public DbSet<Alert> Alerts => Set<Alert>();
    public DbSet<OrderLocalAudit> Orders => Set<OrderLocalAudit>();
    public DbSet<AssetCache> AssetCache => Set<AssetCache>();
    public DbSet<Layout> Layouts => Set<Layout>();
    public DbSet<Panel> Panels => Set<Panel>();
    public DbSet<LinkGroup> LinkGroups => Set<LinkGroup>();
    public DbSet<VideoView> VideoViews => Set<VideoView>();
    public DbSet<VideoInteraction> VideoInteractions => Set<VideoInteraction>();
    public DbSet<CreatorFollow> CreatorFollows => Set<CreatorFollow>();
    public DbSet<UserSymbolInterest> UserSymbolInterests => Set<UserSymbolInterest>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // User
        modelBuilder.Entity<User>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.AuthSub).IsUnique();
            entity.HasIndex(e => e.Email);
            entity.Property(e => e.AuthSub).IsRequired().HasMaxLength(255);
            entity.Property(e => e.Email).IsRequired().HasMaxLength(255);
        });

        // AlpacaLink
        modelBuilder.Entity<AlpacaLink>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => new { e.UserId, e.Env }).IsUnique();
            entity.Property(e => e.AccountId).IsRequired().HasMaxLength(255);
            entity.Property(e => e.ApiKeyId).IsRequired();
            entity.Property(e => e.ApiSecret).IsRequired();
            entity.Property(e => e.Env).IsRequired().HasMaxLength(10);
            entity.HasOne(e => e.User)
                .WithMany(u => u.AlpacaLinks)
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // Watchlist
        modelBuilder.Entity<Watchlist>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => new { e.UserId, e.Name }).IsUnique();
            entity.Property(e => e.Name).IsRequired().HasMaxLength(100);
            entity.HasOne(e => e.User)
                .WithMany(u => u.Watchlists)
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // WatchlistSymbol
        modelBuilder.Entity<WatchlistSymbol>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => new { e.WatchlistId, e.Symbol }).IsUnique();
            entity.Property(e => e.Symbol).IsRequired().HasMaxLength(10);
            entity.HasOne(e => e.Watchlist)
                .WithMany(w => w.Symbols)
                .HasForeignKey(e => e.WatchlistId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // Alert
        modelBuilder.Entity<Alert>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => new { e.UserId, e.Active });
            entity.HasIndex(e => e.Symbol);
            entity.Property(e => e.Symbol).IsRequired().HasMaxLength(10);
            entity.Property(e => e.Operator).IsRequired().HasMaxLength(20);
            entity.Property(e => e.Threshold).HasPrecision(18, 6);
            entity.HasOne(e => e.User)
                .WithMany(u => u.Alerts)
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // OrderLocalAudit
        modelBuilder.Entity<OrderLocalAudit>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.ClientOrderId).IsUnique();
            entity.HasIndex(e => new { e.UserId, e.CreatedAt });
            entity.HasIndex(e => e.AlpacaOrderId);
            entity.Property(e => e.ClientOrderId).IsRequired().HasMaxLength(100);
            entity.Property(e => e.Side).IsRequired().HasMaxLength(10);
            entity.Property(e => e.Symbol).IsRequired().HasMaxLength(10);
            entity.Property(e => e.Qty).HasPrecision(18, 6);
            entity.Property(e => e.LimitPrice).HasPrecision(18, 6);
            entity.Property(e => e.Type).IsRequired().HasMaxLength(10);
            entity.Property(e => e.TimeInForce).IsRequired().HasMaxLength(10);
            entity.Property(e => e.Status).IsRequired().HasMaxLength(50);
            entity.HasOne(e => e.User)
                .WithMany(u => u.Orders)
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // AssetCache
        modelBuilder.Entity<AssetCache>(entity =>
        {
            entity.HasKey(e => e.Symbol);
            entity.HasIndex(e => e.AssetClass);
            entity.HasIndex(e => e.Tradable);
            entity.HasIndex(e => e.LastUpdated);
            entity.Property(e => e.Symbol).HasMaxLength(20);
            entity.Property(e => e.Name).IsRequired().HasMaxLength(255);
            entity.Property(e => e.Exchange).IsRequired().HasMaxLength(20);
            entity.Property(e => e.AssetClass).IsRequired().HasMaxLength(20);
            entity.Property(e => e.MinOrderSize).HasPrecision(18, 8);
            entity.Property(e => e.MinTradeIncrement).HasPrecision(18, 8);
            entity.Property(e => e.PriceIncrement).HasPrecision(18, 8);
        });

        // Layout
        modelBuilder.Entity<Layout>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => new { e.UserId, e.Name }).IsUnique();
            entity.HasIndex(e => new { e.UserId, e.IsDefault });
            entity.Property(e => e.Name).IsRequired().HasMaxLength(100);
            entity.Property(e => e.CompactType).HasMaxLength(20);
            entity.HasOne(e => e.User)
                .WithMany(u => u.Layouts)
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // Panel
        modelBuilder.Entity<Panel>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => new { e.LayoutId, e.PanelId }).IsUnique();
            entity.Property(e => e.PanelId).IsRequired().HasMaxLength(100);
            entity.Property(e => e.Type).IsRequired().HasMaxLength(50);
            entity.Property(e => e.Title).HasMaxLength(100);
            entity.HasOne(e => e.Layout)
                .WithMany(l => l.Panels)
                .HasForeignKey(e => e.LayoutId)
                .OnDelete(DeleteBehavior.Cascade);
            entity.HasOne(e => e.LinkGroup)
                .WithMany(lg => lg.Panels)
                .HasForeignKey(e => e.LinkGroupId)
                .OnDelete(DeleteBehavior.SetNull);
        });

        // LinkGroup
        modelBuilder.Entity<LinkGroup>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => new { e.LayoutId, e.GroupId }).IsUnique();
            entity.Property(e => e.GroupId).IsRequired().HasMaxLength(100);
            entity.Property(e => e.Name).IsRequired().HasMaxLength(50);
            entity.Property(e => e.Color).IsRequired().HasMaxLength(20);
            entity.Property(e => e.Symbol).HasMaxLength(20);
            entity.HasOne(e => e.Layout)
                .WithMany(l => l.LinkGroups)
                .HasForeignKey(e => e.LayoutId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // VideoView
        modelBuilder.Entity<VideoView>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => new { e.UserId, e.VideoId });
            entity.HasOne(e => e.User)
                .WithMany()
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // VideoInteraction
        modelBuilder.Entity<VideoInteraction>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => new { e.UserId, e.VideoId, e.InteractionType }).IsUnique();
            entity.Property(e => e.InteractionType).HasConversion<string>();
            entity.HasOne(e => e.User)
                .WithMany()
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // CreatorFollow
        modelBuilder.Entity<CreatorFollow>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => new { e.UserId, e.CreatorId }).IsUnique();
            entity.HasOne(e => e.User)
                .WithMany()
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // UserSymbolInterest
        modelBuilder.Entity<UserSymbolInterest>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => new { e.UserId, e.Symbol }).IsUnique();
            entity.Property(e => e.Symbol).IsRequired().HasMaxLength(20);
            entity.HasOne(e => e.User)
                .WithMany()
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });
    }
}