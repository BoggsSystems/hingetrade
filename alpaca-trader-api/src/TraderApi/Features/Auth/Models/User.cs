using System.ComponentModel.DataAnnotations.Schema;

namespace TraderApi.Features.Auth.Models;

public enum KycStatus
{
    NotStarted = 0,
    InProgress = 1,
    UnderReview = 2,
    Approved = 3,
    Rejected = 4,
    Expired = 5
}

[Table("AuthUsers")]
public class User
{
    public Guid Id { get; set; }
    public string Email { get; set; } = string.Empty;
    public string Username { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public bool EmailVerified { get; set; }
    public KycStatus KycStatus { get; set; } = KycStatus.NotStarted;
    public DateTime? KycSubmittedAt { get; set; }
    public DateTime? KycApprovedAt { get; set; }
    public string? AlpacaAccountId { get; set; } // Alpaca Broker account ID
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
    
    // Navigation properties
    public ICollection<UserRole> UserRoles { get; set; } = new List<UserRole>();
    public ICollection<RefreshToken> RefreshTokens { get; set; } = new List<RefreshToken>();
    public KycProgress? KycProgress { get; set; }
}

public class Role
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    
    // Navigation properties
    public ICollection<UserRole> UserRoles { get; set; } = new List<UserRole>();
}

public class UserRole
{
    public Guid UserId { get; set; }
    public User User { get; set; } = null!;
    
    public int RoleId { get; set; }
    public Role Role { get; set; } = null!;
}

public class RefreshToken
{
    public int Id { get; set; }
    public Guid UserId { get; set; }
    public string Token { get; set; } = string.Empty;
    public DateTime ExpiresAt { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? RevokedAt { get; set; }
    
    // Navigation properties
    public User User { get; set; } = null!;
    
    public bool IsActive => RevokedAt == null && DateTime.UtcNow < ExpiresAt;
}

public class PasswordResetToken
{
    public int Id { get; set; }
    public Guid UserId { get; set; }
    public string Token { get; set; } = string.Empty;
    public DateTime ExpiresAt { get; set; }
    public DateTime? UsedAt { get; set; }
    
    // Navigation properties
    public User User { get; set; } = null!;
    
    public bool IsValid => UsedAt == null && DateTime.UtcNow < ExpiresAt;
}

[Table("KycProgress")]
public class KycProgress
{
    public Guid UserId { get; set; }
    public User User { get; set; } = null!;
    
    // Track which steps are completed
    public bool HasPersonalInfo { get; set; }
    public bool HasAddress { get; set; }
    public bool HasIdentity { get; set; }
    public bool HasDocuments { get; set; }
    public bool HasFinancialProfile { get; set; }
    public bool HasAgreements { get; set; }
    public bool HasBankAccount { get; set; }
    
    // Store progress data as JSON
    public string? PersonalInfoData { get; set; }
    public string? AddressData { get; set; }
    public string? IdentityData { get; set; }
    public string? DocumentsData { get; set; }
    public string? FinancialProfileData { get; set; }
    public string? AgreementsData { get; set; }
    public string? BankAccountData { get; set; }
    
    public DateTime LastUpdated { get; set; }
    public string? CurrentStep { get; set; }
}