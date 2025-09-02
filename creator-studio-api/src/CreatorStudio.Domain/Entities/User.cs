using Microsoft.AspNetCore.Identity;
using CreatorStudio.Domain.Enums;

namespace CreatorStudio.Domain.Entities;

public class User : IdentityUser<Guid>
{
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string? ProfileImageUrl { get; set; }
    public UserRole Role { get; set; } = UserRole.Viewer;
    public bool IsEmailVerified { get; set; }
    public DateTime? EmailVerifiedAt { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime? LastLoginAt { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    // Navigation properties
    public CreatorProfile? CreatorProfile { get; set; }
    public ICollection<Subscription> Subscriptions { get; set; } = new List<Subscription>();
    public ICollection<VideoView> VideoViews { get; set; } = new List<VideoView>();
    public ICollection<Video> Videos { get; set; } = new List<Video>();

    // Helper properties
    public string FullName => $"{FirstName} {LastName}".Trim();
    public bool IsCreator => CreatorProfile != null;
}