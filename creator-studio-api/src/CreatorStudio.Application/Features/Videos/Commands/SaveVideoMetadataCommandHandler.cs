using CreatorStudio.Application.DTOs;
using CreatorStudio.Domain.Entities;
using CreatorStudio.Domain.Enums;
using CreatorStudio.Domain.Interfaces;
using Microsoft.AspNetCore.Identity;
using MediatR;

namespace CreatorStudio.Application.Features.Videos.Commands;

public class SaveVideoMetadataCommandHandler : IRequestHandler<SaveVideoMetadataCommand, VideoDto>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly UserManager<User> _userManager;

    public SaveVideoMetadataCommandHandler(
        IUnitOfWork unitOfWork,
        UserManager<User> userManager)
    {
        _unitOfWork = unitOfWork;
        _userManager = userManager;
    }

    public async Task<VideoDto> Handle(SaveVideoMetadataCommand request, CancellationToken cancellationToken)
    {
        var metadata = request.VideoMetadata;

        // Try to find user, create a placeholder if not found
        var user = await _userManager.FindByIdAsync(metadata.UserId.ToString());
        if (user == null)
        {
            
            // For development: create a placeholder user entry
            // In production, this should be handled through proper user sync
            user = new User
            {
                Id = metadata.UserId,
                Email = $"placeholder+{metadata.UserId}@example.com",
                FirstName = "Placeholder",
                LastName = "User", 
                UserName = $"user_{metadata.UserId}",
                EmailConfirmed = true
            };
            
            var result = await _userManager.CreateAsync(user);
            if (!result.Succeeded)
            {
                throw new ArgumentException($"Failed to create placeholder user: {string.Join(", ", result.Errors.Select(e => e.Description))}");
            }
        }

        // Create video entity
        var video = new Video
        {
            Id = Guid.NewGuid(),
            CreatorId = metadata.UserId,
            Title = metadata.Title,
            Description = metadata.Description,
            CloudinaryPublicId = metadata.CloudinaryPublicId,
            ThumbnailUrl = metadata.ThumbnailUrl,
            VideoUrl = metadata.VideoUrl,
            DurationSeconds = metadata.Duration.HasValue ? (int)Math.Round(metadata.Duration.Value) : null,
            FileSizeBytes = metadata.FileSize,
            Status = VideoStatus.Processing,
            Visibility = VideoVisibility.Public,
            IsSubscriberOnly = false,
            ProcessingStatus = ProcessingStatus.Pending,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        // Handle tags if provided
        if (metadata.Tags?.Any() == true)
        {
            // Store tags as string array for now (as defined in the Video entity)
            video.Tags = metadata.Tags;
        }

        // Save to database
        var videoRepository = _unitOfWork.Repository<Video>();
        await videoRepository.AddAsync(video, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        // Return DTO
        return new VideoDto
        {
            Id = video.Id,
            CreatorId = video.CreatorId,
            Title = video.Title,
            Description = video.Description,
            ThumbnailUrl = video.ThumbnailUrl,
            VideoUrl = video.VideoUrl,
            Status = video.Status,
            Visibility = video.Visibility,
            DurationSeconds = video.DurationSeconds,
            FileSizeBytes = video.FileSizeBytes,
            Tags = video.Tags,
            CreatedAt = video.CreatedAt,
            IsSubscriberOnly = video.IsSubscriberOnly,
            ViewCount = 0,
            AverageWatchTime = 0,
            EngagementRate = 0,
            MinimumSubscriptionTier = SubscriptionTier.Free,
            CreatorDisplayName = user.FullName ?? user.Email
        };
    }
}