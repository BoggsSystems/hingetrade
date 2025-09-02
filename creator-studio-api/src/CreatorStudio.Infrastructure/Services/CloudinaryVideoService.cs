using CloudinaryDotNet;
using CloudinaryDotNet.Actions;
using CreatorStudio.Domain.Enums;
using CreatorStudio.Domain.Interfaces;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using VideoUploadResult = CreatorStudio.Domain.Interfaces.VideoUploadResult;

namespace CreatorStudio.Infrastructure.Services;

public class CloudinaryVideoService : IVideoProcessingService
{
    private readonly Cloudinary _cloudinary;
    private readonly IConfiguration _configuration;
    private readonly ILogger<CloudinaryVideoService> _logger;
    private readonly string _baseNotificationUrl;

    public CloudinaryVideoService(
        IConfiguration configuration,
        ILogger<CloudinaryVideoService> logger)
    {
        _configuration = configuration;
        _logger = logger;

        var cloudinaryUrl = _configuration.GetConnectionString("Cloudinary");
        if (string.IsNullOrEmpty(cloudinaryUrl))
        {
            throw new InvalidOperationException("Cloudinary connection string is required");
        }

        _cloudinary = new Cloudinary(cloudinaryUrl);
        _baseNotificationUrl = _configuration["ApiBaseUrl"] ?? "http://localhost:5000";
    }

    public async Task<VideoUploadResult> UploadVideoAsync(VideoUploadRequest request, CancellationToken cancellationToken = default)
    {
        try
        {
            var uploadParams = new VideoUploadParams()
            {
                File = new FileDescription(request.FileName, request.VideoStream),
                Folder = "creator-studio/videos",
                PublicId = Guid.NewGuid().ToString(),
                NotificationUrl = $"{_baseNotificationUrl}/api/webhooks/cloudinary"
            };

            var result = await _cloudinary.UploadAsync(uploadParams);

            if (result.Error != null)
            {
                _logger.LogError("Cloudinary upload failed: {Error}", result.Error.Message);
                return new VideoUploadResult
                {
                    ProcessingStatus = ProcessingStatus.Failed,
                    ProcessingError = result.Error.Message
                };
            }

            _logger.LogInformation("Video uploaded successfully to Cloudinary: {PublicId}", result.PublicId);

            return new VideoUploadResult
            {
                CloudinaryVideoId = result.PublicId,
                CloudinaryPublicId = result.PublicId,
                VideoUrl = result.SecureUrl?.ToString() ?? "",
                ThumbnailUrl = GetThumbnailUrlSync(result.PublicId),
                DurationSeconds = (int)result.Duration,
                FileSizeBytes = result.Bytes,
                ProcessingStatus = ProcessingStatus.Completed
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error uploading video to Cloudinary");
            return new VideoUploadResult
            {
                ProcessingStatus = ProcessingStatus.Failed,
                ProcessingError = ex.Message
            };
        }
    }

    public async Task<string> GetStreamingUrlAsync(string videoId, VideoQuality quality = VideoQuality.Auto, CancellationToken cancellationToken = default)
    {
        try
        {
            var url = _cloudinary.Api.UrlVideoUp
                .Secure(true)
                .BuildUrl(videoId);

            return await Task.FromResult(url);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error generating streaming URL for video {VideoId}", videoId);
            throw;
        }
    }

    public async Task<TranscriptionResult> GetTranscriptionAsync(string videoId, CancellationToken cancellationToken = default)
    {
        // Simplified implementation - return empty for now
        return await Task.FromResult(new TranscriptionResult
        {
            Text = "",
            Language = "en",
            Confidence = 0
        });
    }

    public async Task<VideoAnalysisResult> AnalyzeVideoAsync(string videoId, CancellationToken cancellationToken = default)
    {
        // Simplified implementation - return empty for now
        return await Task.FromResult(new VideoAnalysisResult());
    }

    public async Task<VideoProcessingStatus> GetProcessingStatusAsync(string videoId, CancellationToken cancellationToken = default)
    {
        try
        {
            var resource = await _cloudinary.GetResourceAsync(new GetResourceParams(videoId));

            if (resource.Error != null)
            {
                return new VideoProcessingStatus
                {
                    Status = ProcessingStatus.Failed,
                    Error = resource.Error.Message
                };
            }

            return new VideoProcessingStatus
            {
                Status = ProcessingStatus.Completed,
                ProgressPercentage = 100,
                CurrentStep = "Complete"
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error checking processing status for video {VideoId}", videoId);
            return new VideoProcessingStatus
            {
                Status = ProcessingStatus.Failed,
                Error = ex.Message
            };
        }
    }

    public async Task<bool> DeleteVideoAsync(string videoId, CancellationToken cancellationToken = default)
    {
        try
        {
            var result = await _cloudinary.DestroyAsync(new DeletionParams(videoId)
            {
                Invalidate = true
            });

            if (result.Error != null)
            {
                _logger.LogError("Failed to delete video {VideoId}: {Error}", videoId, result.Error.Message);
                return false;
            }

            _logger.LogInformation("Successfully deleted video {VideoId}", videoId);
            return result.Result == "ok";
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting video {VideoId}", videoId);
            return false;
        }
    }

    public async Task<string> GetThumbnailUrlAsync(string videoId, int width = 640, int height = 360, CancellationToken cancellationToken = default)
    {
        return await Task.FromResult(GetThumbnailUrlSync(videoId, width, height));
    }

    private string GetThumbnailUrlSync(string videoId, int width = 640, int height = 360)
    {
        var transformation = new Transformation()
            .Width(width)
            .Height(height)
            .Crop("fill")
            .Quality("auto");

        return _cloudinary.Api.UrlVideoUp
            .Transform(transformation)
            .Secure(true)
            .BuildUrl(videoId + ".jpg");
    }
}