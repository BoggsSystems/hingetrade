using CreatorStudio.Domain.Entities;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;

namespace CreatorStudio.Infrastructure.Data;

public class CreatorStudioDbContext : IdentityDbContext<User, IdentityRole<Guid>, Guid>
{
    public CreatorStudioDbContext(DbContextOptions<CreatorStudioDbContext> options) : base(options)
    {
    }

    public DbSet<CreatorProfile> CreatorProfiles => Set<CreatorProfile>();
    public DbSet<Video> Videos => Set<Video>();
    public DbSet<VideoView> VideoViews => Set<VideoView>();
    public DbSet<VideoAnalytics> VideoAnalytics => Set<VideoAnalytics>();
    public DbSet<Subscription> Subscriptions => Set<Subscription>();
    public DbSet<Tag> Tags => Set<Tag>();
    public DbSet<VideoTag> VideoTags => Set<VideoTag>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Configure User entity (extends IdentityUser)
        modelBuilder.Entity<User>(entity =>
        {
            entity.Property(e => e.FirstName)
                .IsRequired()
                .HasMaxLength(100);
                
            entity.Property(e => e.LastName)
                .IsRequired()
                .HasMaxLength(100);

            entity.Property(e => e.ProfileImageUrl)
                .HasMaxLength(500);

            entity.Property(e => e.Role)
                .HasConversion<string>()
                .HasMaxLength(20);

            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("NOW()");

            entity.Property(e => e.UpdatedAt)
                .HasDefaultValueSql("NOW()");

            // One-to-one relationship with CreatorProfile
            entity.HasOne(e => e.CreatorProfile)
                .WithOne(e => e.User)
                .HasForeignKey<CreatorProfile>(e => e.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // Configure CreatorProfile entity
        modelBuilder.Entity<CreatorProfile>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.DisplayName);
            
            entity.Property(e => e.DisplayName)
                .IsRequired()
                .HasMaxLength(255);

            entity.Property(e => e.Bio)
                .HasMaxLength(2000);

            entity.Property(e => e.ProfileImageUrl)
                .HasMaxLength(500);

            entity.Property(e => e.BannerImageUrl)
                .HasMaxLength(500);

            entity.Property(e => e.Website)
                .HasMaxLength(255);

            entity.Property(e => e.TwitterHandle)
                .HasMaxLength(100);

            entity.Property(e => e.LinkedInProfile)
                .HasMaxLength(255);

            entity.Property(e => e.TotalRevenue)
                .HasPrecision(18, 2);

            entity.Property(e => e.MonthlySubscriptionPrice)
                .HasPrecision(18, 2);

            entity.Property(e => e.PremiumSubscriptionPrice)
                .HasPrecision(18, 2);

            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("NOW()");

            entity.Property(e => e.UpdatedAt)
                .HasDefaultValueSql("NOW()");
        });

        // Configure Video entity
        modelBuilder.Entity<Video>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.CreatorId);
            entity.HasIndex(e => e.Status);
            entity.HasIndex(e => e.PublishedAt);
            
            entity.Property(e => e.Title)
                .IsRequired()
                .HasMaxLength(500);

            entity.Property(e => e.Description)
                .HasMaxLength(5000);

            entity.Property(e => e.ThumbnailUrl)
                .HasMaxLength(500);

            entity.Property(e => e.Status)
                .HasConversion<string>()
                .HasMaxLength(20);

            entity.Property(e => e.Visibility)
                .HasConversion<string>()
                .HasMaxLength(20);

            entity.Property(e => e.ProcessingStatus)
                .HasConversion<string>()
                .HasMaxLength(20);

            entity.Property(e => e.CloudinaryVideoId)
                .HasMaxLength(255);

            entity.Property(e => e.CloudinaryPublicId)
                .HasMaxLength(255);

            entity.Property(e => e.OriginalFileName)
                .HasMaxLength(255);

            entity.Property(e => e.VideoUrl)
                .HasMaxLength(500);

            entity.Property(e => e.ProcessingError)
                .HasMaxLength(2000);

            // Array properties
            entity.Property(e => e.Tags)
                .HasColumnType("text[]");

            entity.Property(e => e.TradingSymbols)
                .HasColumnType("text[]");

            entity.Property(e => e.TranscriptionText)
                .HasColumnType("text");

            entity.Property(e => e.AverageWatchTime)
                .HasPrecision(18, 2);

            entity.Property(e => e.EngagementRate)
                .HasPrecision(18, 4);

            entity.Property(e => e.MinimumSubscriptionTier)
                .HasConversion<string>()
                .HasMaxLength(20);

            entity.Property(e => e.PurchasePrice)
                .HasPrecision(18, 2);

            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("NOW()");

            entity.Property(e => e.UpdatedAt)
                .HasDefaultValueSql("NOW()");

            // Relationships
            entity.HasOne(e => e.User)
                .WithMany(e => e.Videos)
                .HasForeignKey(e => e.CreatorId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // Configure VideoView entity
        modelBuilder.Entity<VideoView>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.VideoId);
            entity.HasIndex(e => e.UserId);
            entity.HasIndex(e => new { e.VideoId, e.UserId });
            entity.HasIndex(e => e.CreatedAt);

            entity.Property(e => e.IpAddress)
                .IsRequired()
                .HasMaxLength(45); // IPv6 max length

            entity.Property(e => e.UserAgent)
                .HasMaxLength(500);

            entity.Property(e => e.Country)
                .HasMaxLength(100);

            entity.Property(e => e.City)
                .HasMaxLength(100);

            entity.Property(e => e.AnonymousId)
                .HasMaxLength(100);

            entity.Property(e => e.WatchPercentage)
                .HasPrecision(5, 2);

            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("NOW()");

            // Relationships
            entity.HasOne(e => e.Video)
                .WithMany(e => e.Views)
                .HasForeignKey(e => e.VideoId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(e => e.User)
                .WithMany(e => e.VideoViews)
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.SetNull);
        });

        // Configure VideoAnalytics entity
        modelBuilder.Entity<VideoAnalytics>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.VideoId);
            entity.HasIndex(e => e.Date);
            entity.HasIndex(e => new { e.VideoId, e.Date }).IsUnique();

            entity.Property(e => e.AverageWatchTimeSeconds)
                .HasPrecision(18, 2);

            entity.Property(e => e.WatchTimePercentage)
                .HasPrecision(5, 2);

            entity.Property(e => e.EngagementRate)
                .HasPrecision(5, 4);

            entity.Property(e => e.Revenue)
                .HasPrecision(18, 2);

            entity.Property(e => e.TipRevenue)
                .HasPrecision(18, 2);

            // JSON columns
            entity.Property(e => e.TopCountries)
                .HasColumnType("jsonb");

            entity.Property(e => e.AgeGroupDistribution)
                .HasColumnType("jsonb");

            entity.Property(e => e.DeviceTypes)
                .HasColumnType("jsonb");

            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("NOW()");

            // Relationships
            entity.HasOne(e => e.Video)
                .WithMany(e => e.Analytics)
                .HasForeignKey(e => e.VideoId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // Configure Subscription entity
        modelBuilder.Entity<Subscription>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.UserId);
            entity.HasIndex(e => e.CreatorId);
            entity.HasIndex(e => new { e.UserId, e.CreatorId }).IsUnique();
            entity.HasIndex(e => e.Status);

            entity.Property(e => e.Tier)
                .HasConversion<string>()
                .HasMaxLength(20);

            entity.Property(e => e.Status)
                .HasConversion<string>()
                .HasMaxLength(20);

            entity.Property(e => e.Price)
                .HasPrecision(18, 2);

            entity.Property(e => e.Currency)
                .IsRequired()
                .HasMaxLength(3);

            entity.Property(e => e.CancellationReason)
                .HasMaxLength(500);

            entity.Property(e => e.StripeSubscriptionId)
                .HasMaxLength(255);

            entity.Property(e => e.PaymentMethodId)
                .HasMaxLength(255);

            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("NOW()");

            entity.Property(e => e.UpdatedAt)
                .HasDefaultValueSql("NOW()");

            // Relationships
            entity.HasOne(e => e.User)
                .WithMany(e => e.Subscriptions)
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(e => e.Creator)
                .WithMany(e => e.Subscribers)
                .HasForeignKey(e => e.CreatorId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // Configure Tag entity
        modelBuilder.Entity<Tag>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.Name).IsUnique();
            entity.HasIndex(e => e.Slug).IsUnique();

            entity.Property(e => e.Name)
                .IsRequired()
                .HasMaxLength(100);

            entity.Property(e => e.Slug)
                .IsRequired()
                .HasMaxLength(100);

            entity.Property(e => e.Description)
                .HasMaxLength(500);

            entity.Property(e => e.Color)
                .HasMaxLength(7); // Hex color code

            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("NOW()");
        });

        // Configure VideoTag entity (many-to-many)
        modelBuilder.Entity<VideoTag>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => new { e.VideoId, e.TagId }).IsUnique();

            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("NOW()");

            entity.HasOne(e => e.Video)
                .WithMany(e => e.VideoTags)
                .HasForeignKey(e => e.VideoId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(e => e.Tag)
                .WithMany(e => e.VideoTags)
                .HasForeignKey(e => e.TagId)
                .OnDelete(DeleteBehavior.Cascade);
        });
    }

    public override async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        UpdateTimestamps();
        return await base.SaveChangesAsync(cancellationToken);
    }

    public override int SaveChanges()
    {
        UpdateTimestamps();
        return base.SaveChanges();
    }

    private void UpdateTimestamps()
    {
        var entities = ChangeTracker.Entries()
            .Where(x => x.Entity is Domain.Common.BaseEntity && 
                       (x.State == EntityState.Added || x.State == EntityState.Modified));

        foreach (var entity in entities)
        {
            var baseEntity = (Domain.Common.BaseEntity)entity.Entity;
            
            if (entity.State == EntityState.Added)
            {
                baseEntity.CreatedAt = DateTime.UtcNow;
            }
            
            if (entity.State == EntityState.Modified)
            {
                baseEntity.UpdatedAt = DateTime.UtcNow;
            }
        }
    }
}