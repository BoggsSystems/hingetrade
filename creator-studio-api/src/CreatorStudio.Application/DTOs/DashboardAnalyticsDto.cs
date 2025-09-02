namespace CreatorStudio.Application.DTOs;

public class DashboardAnalyticsDto
{
    public int TotalVideos { get; set; }
    public int PublishedVideos { get; set; }
    public long TotalViews { get; set; }
    public long UniqueViews { get; set; }
    public double TotalWatchTimeHours { get; set; }
    public int Subscribers { get; set; }
    public decimal Revenue { get; set; }
    public decimal MonthlyGrowthPercentage { get; set; }
    public MonthlyAnalyticsDto ThisMonth { get; set; } = new();
    public List<TopVideoDto> TopVideos { get; set; } = new();
}

public class MonthlyAnalyticsDto
{
    public long Views { get; set; }
    public double WatchTimeHours { get; set; }
    public decimal Revenue { get; set; }
    public decimal ViewsGrowthPercentage { get; set; }
    public decimal WatchTimeGrowthPercentage { get; set; }
    public decimal RevenueGrowthPercentage { get; set; }
}

public class TopVideoDto
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? ThumbnailUrl { get; set; }
    public long Views { get; set; }
    public double WatchTimeHours { get; set; }
    public decimal EngagementRate { get; set; }
}