namespace CreatorStudio.Application.DTOs;

public class VideoAnalyticsDto
{
    public Guid VideoId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? ThumbnailUrl { get; set; }
    public DateTime CreatedAt { get; set; }
    public long Views { get; set; }
    public long UniqueViews { get; set; }
    public double AverageWatchTimeSeconds { get; set; }
    public double TotalWatchTimeHours { get; set; }
    public decimal CompletionRate { get; set; }
    public decimal EngagementRate { get; set; }
    public int Likes { get; set; }
    public int Shares { get; set; }
    public int Comments { get; set; }
    public Dictionary<string, int> TrafficSources { get; set; } = new();
    public Dictionary<string, int> DeviceTypes { get; set; } = new();
    public List<DailyViewsDto> DailyViews { get; set; } = new();
}

public class DailyViewsDto
{
    public DateTime Date { get; set; }
    public long Views { get; set; }
    public double WatchTimeHours { get; set; }
}