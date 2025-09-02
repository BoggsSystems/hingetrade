using CreatorStudio.Domain.Common;

namespace CreatorStudio.Domain.Entities;

public class Tag : BaseEntity
{
    public string Name { get; set; } = string.Empty;
    public string Slug { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? Color { get; set; }
    public int UseCount { get; set; }
    public bool IsActive { get; set; } = true;

    // Navigation properties
    public ICollection<VideoTag> VideoTags { get; set; } = new List<VideoTag>();
}

public class VideoTag : BaseEntity
{
    public Guid VideoId { get; set; }
    public Guid TagId { get; set; }

    // Navigation properties
    public Video Video { get; set; } = null!;
    public Tag Tag { get; set; } = null!;
}