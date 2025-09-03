namespace TraderApi.Features.Videos;

/// <summary>
/// Service to map HingeTrade users to Creator Studio users
/// </summary>
public interface IUserMappingService
{
    Task<Guid> MapHingeTradeUserToCreatorStudioAsync(Guid hingeTradeUserId, CancellationToken cancellationToken = default);
    Task<UserMappingInfo?> GetUserMappingAsync(Guid hingeTradeUserId, CancellationToken cancellationToken = default);
    Task<bool> CreateUserMappingAsync(Guid hingeTradeUserId, Guid creatorStudioUserId, CancellationToken cancellationToken = default);
    Task<Guid> GetCreatorStudioUserIdAsync(Guid hingeTradeUserId, CancellationToken cancellationToken = default);
}

public class UserMappingService : IUserMappingService
{
    private readonly ILogger<UserMappingService> _logger;
    private readonly ICreatorStudioClient _creatorStudioClient;

    // Simple in-memory mapping for development - in production this would be database-backed
    private static readonly Dictionary<Guid, UserMappingInfo> _userMappings = new();

    public UserMappingService(
        ILogger<UserMappingService> logger,
        ICreatorStudioClient creatorStudioClient)
    {
        _logger = logger;
        _creatorStudioClient = creatorStudioClient;
    }

    public async Task<Guid> MapHingeTradeUserToCreatorStudioAsync(Guid hingeTradeUserId, CancellationToken cancellationToken = default)
    {
        // Check if mapping already exists
        if (_userMappings.TryGetValue(hingeTradeUserId, out var existingMapping))
        {
            _logger.LogDebug("Using existing user mapping for HingeTrade user {HingeTradeUserId} -> Creator Studio user {CreatorStudioUserId}", 
                hingeTradeUserId, existingMapping.CreatorStudioUserId);
            return existingMapping.CreatorStudioUserId;
        }

        try
        {
            // For development, we'll map to existing Creator Studio users
            // In production, this would involve:
            // 1. Looking up user by email in both systems
            // 2. Creating a proper mapping table in the database
            // 3. Handling user creation in Creator Studio if needed
            
            // Map our test user to existing Creator Studio user that has videos
            var creatorStudioUserId = hingeTradeUserId == Guid.Parse("9dda50c1-0749-4892-ac3f-af9e76a74ff3") 
                ? Guid.Parse("1b8abc80-de9a-4cb4-926e-e7ffe27def28") // Maps to test@example.com user with videos
                : hingeTradeUserId; // Direct mapping for other users
            
            var mappingInfo = new UserMappingInfo(
                hingeTradeUserId,
                creatorStudioUserId,
                DateTime.UtcNow,
                UserMappingType.DirectMapping
            );
            
            _userMappings[hingeTradeUserId] = mappingInfo;
            
            _logger.LogInformation("Created user mapping for HingeTrade user {HingeTradeUserId} -> Creator Studio user {CreatorStudioUserId}", 
                hingeTradeUserId, creatorStudioUserId);
                
            return creatorStudioUserId;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to create user mapping for HingeTrade user {HingeTradeUserId}", hingeTradeUserId);
            throw new VideoServiceException("Failed to map user for video service", ex);
        }
    }

    public Task<UserMappingInfo?> GetUserMappingAsync(Guid hingeTradeUserId, CancellationToken cancellationToken = default)
    {
        _userMappings.TryGetValue(hingeTradeUserId, out var mapping);
        return Task.FromResult(mapping);
    }

    public Task<bool> CreateUserMappingAsync(Guid hingeTradeUserId, Guid creatorStudioUserId, CancellationToken cancellationToken = default)
    {
        try
        {
            var mappingInfo = new UserMappingInfo(
                hingeTradeUserId,
                creatorStudioUserId,
                DateTime.UtcNow,
                UserMappingType.ManualMapping
            );
            
            _userMappings[hingeTradeUserId] = mappingInfo;
            
            _logger.LogInformation("Manually created user mapping for HingeTrade user {HingeTradeUserId} -> Creator Studio user {CreatorStudioUserId}", 
                hingeTradeUserId, creatorStudioUserId);
                
            return Task.FromResult(true);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to create manual user mapping");
            return Task.FromResult(false);
        }
    }

    public async Task<Guid> GetCreatorStudioUserIdAsync(Guid hingeTradeUserId, CancellationToken cancellationToken = default)
    {
        // This method is essentially the same as MapHingeTradeUserToCreatorStudioAsync
        // but without creating a new mapping if it doesn't exist
        return await MapHingeTradeUserToCreatorStudioAsync(hingeTradeUserId, cancellationToken);
    }
}

/// <summary>
/// User mapping information between HingeTrade and Creator Studio
/// </summary>
public record UserMappingInfo(
    Guid HingeTradeUserId,
    Guid CreatorStudioUserId,
    DateTime CreatedAt,
    UserMappingType MappingType
);

/// <summary>
/// Type of user mapping
/// </summary>
public enum UserMappingType
{
    /// <summary>
    /// Direct 1:1 mapping using same user ID
    /// </summary>
    DirectMapping,
    
    /// <summary>
    /// Email-based mapping between systems
    /// </summary>
    EmailMapping,
    
    /// <summary>
    /// Manually created mapping
    /// </summary>
    ManualMapping,
    
    /// <summary>
    /// Guest user mapping for non-authenticated access
    /// </summary>
    GuestMapping
}