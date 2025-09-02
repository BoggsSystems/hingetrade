using CreatorStudio.Domain.Enums;

namespace CreatorStudio.Domain.Interfaces;

public interface IVideoProcessingService
{
    Task<VideoUploadResult> UploadVideoAsync(VideoUploadRequest request, CancellationToken cancellationToken = default);
    Task<string> GetStreamingUrlAsync(string videoId, VideoQuality quality = VideoQuality.Auto, CancellationToken cancellationToken = default);
    Task<TranscriptionResult> GetTranscriptionAsync(string videoId, CancellationToken cancellationToken = default);
    Task<VideoAnalysisResult> AnalyzeVideoAsync(string videoId, CancellationToken cancellationToken = default);
    Task<VideoProcessingStatus> GetProcessingStatusAsync(string videoId, CancellationToken cancellationToken = default);
    Task<bool> DeleteVideoAsync(string videoId, CancellationToken cancellationToken = default);
    Task<string> GetThumbnailUrlAsync(string videoId, int width = 640, int height = 360, CancellationToken cancellationToken = default);
}

public class VideoUploadRequest
{
    public Stream VideoStream { get; set; } = null!;
    public string FileName { get; set; } = string.Empty;
    public string? Title { get; set; }
    public string? Description { get; set; }
    public string[]? Tags { get; set; }
    public bool AutoTranscribe { get; set; } = true;
    public bool AutoAnalyze { get; set; } = true;
    public VideoQuality TargetQuality { get; set; } = VideoQuality.Auto;
}

public class VideoUploadResult
{
    public string CloudinaryVideoId { get; set; } = string.Empty;
    public string CloudinaryPublicId { get; set; } = string.Empty;
    public string VideoUrl { get; set; } = string.Empty;
    public string ThumbnailUrl { get; set; } = string.Empty;
    public int DurationSeconds { get; set; }
    public long FileSizeBytes { get; set; }
    public ProcessingStatus ProcessingStatus { get; set; }
    public string? ProcessingError { get; set; }
}

public class TranscriptionResult
{
    public string Text { get; set; } = string.Empty;
    public TimecodedSegment[]? Segments { get; set; }
    public string Language { get; set; } = "en";
    public decimal Confidence { get; set; }
}

public class TimecodedSegment
{
    public int StartTimeSeconds { get; set; }
    public int EndTimeSeconds { get; set; }
    public string Text { get; set; } = string.Empty;
    public decimal Confidence { get; set; }
}

public class VideoAnalysisResult
{
    public string[]? DetectedSymbols { get; set; }
    public string[]? DetectedKeywords { get; set; }
    public string[]? SuggestedTags { get; set; }
    public ContentCategory[]? Categories { get; set; }
    public decimal? SentimentScore { get; set; }
    public string? Summary { get; set; }
}

public class ContentCategory
{
    public string Name { get; set; } = string.Empty;
    public decimal Confidence { get; set; }
}

public class VideoProcessingStatus
{
    public ProcessingStatus Status { get; set; }
    public int ProgressPercentage { get; set; }
    public string? CurrentStep { get; set; }
    public string? Error { get; set; }
    public DateTime? StartedAt { get; set; }
    public DateTime? CompletedAt { get; set; }
    public TimeSpan? EstimatedTimeRemaining { get; set; }
}