namespace CreatorStudio.API.Models;

/// <summary>
/// Request model for unpublishing a video
/// </summary>
public class UnpublishVideoRequest
{
    /// <summary>
    /// Optional reason for unpublishing the video
    /// </summary>
    public string? Reason { get; set; }
}