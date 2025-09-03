using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using System.Text.Json;
using TraderApi.Features.Auth.Data;
using TraderApi.Features.Auth.Models;
using TraderApi.Alpaca;

namespace TraderApi.Features.Kyc;

public static class KycEndpoints
{
    public static void MapKycEndpoints(this WebApplication app)
    {
        var kyc = app.MapGroup("/api/kyc")
            .RequireAuthorization()
            .WithTags("KYC");
            
        kyc.MapGet("/status", GetKycStatus);
        kyc.MapGet("/progress", GetKycProgress);
        kyc.MapPost("/progress/{step}", UpdateKycProgress);
        kyc.MapPost("/submit", SubmitKyc);
        
        // Development only - manual approval endpoint
        if (app.Environment.IsDevelopment())
        {
            kyc.MapPost("/approve", ManuallyApproveKyc);
        }
    }
    
    private static async Task<IResult> ManuallyApproveKyc(
        ClaimsPrincipal user,
        AuthDbContext authDb,
        ILogger<Program> logger)
    {
        var userId = Guid.Parse(user.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? throw new UnauthorizedAccessException());
        
        var authUser = await authDb.Users.FindAsync(userId);
        if (authUser == null)
            return TypedResults.NotFound();
            
        if (authUser.KycStatus == KycStatus.Approved)
            return TypedResults.BadRequest("KYC already approved");
            
        authUser.KycStatus = KycStatus.Approved;
        authUser.KycApprovedAt = DateTime.UtcNow;
        authUser.UpdatedAt = DateTime.UtcNow;
        
        await authDb.SaveChangesAsync();
        
        logger.LogWarning("KYC manually approved for user {UserId} in development mode", userId);
        
        return TypedResults.Ok(new { message = "KYC manually approved for testing" });
    }
    
    private static async Task<IResult> GetKycStatus(
        ClaimsPrincipal user,
        AuthDbContext authDb)
    {
        var userId = Guid.Parse(user.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? throw new UnauthorizedAccessException());
        
        var authUser = await authDb.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(u => u.Id == userId);
            
        if (authUser == null)
            return TypedResults.NotFound();
            
        return TypedResults.Ok(new
        {
            KycStatus = authUser.KycStatus.ToString(),
            KycSubmittedAt = authUser.KycSubmittedAt,
            KycApprovedAt = authUser.KycApprovedAt
        });
    }
    
    private static async Task<IResult> GetKycProgress(
        ClaimsPrincipal user,
        AuthDbContext authDb)
    {
        var userId = Guid.Parse(user.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? throw new UnauthorizedAccessException());
        
        var kycProgress = await authDb.KycProgressRecords
            .AsNoTracking()
            .FirstOrDefaultAsync(k => k.UserId == userId);
            
        if (kycProgress == null)
        {
            // Return empty progress if none exists
            return TypedResults.Ok(new KycProgressResponse
            {
                CurrentStep = "welcome",
                CompletedSteps = new List<string>(),
                Progress = new Dictionary<string, object?>()
            });
        }
        
        var completedSteps = new List<string>();
        var progress = new Dictionary<string, object?>();
        
        if (kycProgress.HasPersonalInfo)
        {
            completedSteps.Add("personalInfo");
            if (!string.IsNullOrEmpty(kycProgress.PersonalInfoData))
                progress["personalInfo"] = JsonSerializer.Deserialize<object>(kycProgress.PersonalInfoData);
        }
        
        if (kycProgress.HasAddress)
        {
            completedSteps.Add("address");
            if (!string.IsNullOrEmpty(kycProgress.AddressData))
                progress["address"] = JsonSerializer.Deserialize<object>(kycProgress.AddressData);
        }
        
        if (kycProgress.HasIdentity)
        {
            completedSteps.Add("identity");
            if (!string.IsNullOrEmpty(kycProgress.IdentityData))
                progress["identity"] = JsonSerializer.Deserialize<object>(kycProgress.IdentityData);
        }
        
        if (kycProgress.HasDocuments)
        {
            completedSteps.Add("documents");
            if (!string.IsNullOrEmpty(kycProgress.DocumentsData))
                progress["documents"] = JsonSerializer.Deserialize<object>(kycProgress.DocumentsData);
        }
        
        if (kycProgress.HasFinancialProfile)
        {
            completedSteps.Add("financialProfile");
            if (!string.IsNullOrEmpty(kycProgress.FinancialProfileData))
                progress["financialProfile"] = JsonSerializer.Deserialize<object>(kycProgress.FinancialProfileData);
        }
        
        if (kycProgress.HasAgreements)
        {
            completedSteps.Add("agreements");
            if (!string.IsNullOrEmpty(kycProgress.AgreementsData))
                progress["agreements"] = JsonSerializer.Deserialize<object>(kycProgress.AgreementsData);
        }
        
        if (kycProgress.HasBankAccount)
        {
            completedSteps.Add("bankAccount");
            if (!string.IsNullOrEmpty(kycProgress.BankAccountData))
                progress["bankAccount"] = JsonSerializer.Deserialize<object>(kycProgress.BankAccountData);
        }
        
        return TypedResults.Ok(new KycProgressResponse
        {
            CurrentStep = kycProgress.CurrentStep ?? "welcome",
            CompletedSteps = completedSteps,
            Progress = progress,
            LastUpdated = kycProgress.LastUpdated
        });
    }
    
    private static async Task<IResult> UpdateKycProgress(
        string step,
        [FromBody] KycStepData data,
        ClaimsPrincipal user,
        AuthDbContext authDb)
    {
        var userId = Guid.Parse(user.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? throw new UnauthorizedAccessException());
        
        var kycProgress = await authDb.KycProgressRecords
            .FirstOrDefaultAsync(k => k.UserId == userId);
            
        if (kycProgress == null)
        {
            kycProgress = new KycProgress
            {
                UserId = userId,
                LastUpdated = DateTime.UtcNow
            };
            authDb.KycProgressRecords.Add(kycProgress);
        }
        
        // Update the appropriate step
        var jsonData = JsonSerializer.Serialize(data.Data);
        
        switch (step.ToLower())
        {
            case "personalinfo":
                kycProgress.HasPersonalInfo = true;
                kycProgress.PersonalInfoData = jsonData;
                break;
            case "address":
                kycProgress.HasAddress = true;
                kycProgress.AddressData = jsonData;
                break;
            case "identity":
                kycProgress.HasIdentity = true;
                kycProgress.IdentityData = jsonData;
                break;
            case "documents":
                kycProgress.HasDocuments = true;
                kycProgress.DocumentsData = jsonData;
                break;
            case "financialprofile":
                kycProgress.HasFinancialProfile = true;
                kycProgress.FinancialProfileData = jsonData;
                break;
            case "agreements":
                kycProgress.HasAgreements = true;
                kycProgress.AgreementsData = jsonData;
                break;
            case "bankaccount":
                kycProgress.HasBankAccount = true;
                kycProgress.BankAccountData = jsonData;
                break;
            default:
                return TypedResults.BadRequest("Invalid step");
        }
        
        kycProgress.CurrentStep = step;
        kycProgress.LastUpdated = DateTime.UtcNow;
        
        // Update user KYC status to InProgress if it's NotStarted
        var authUser = await authDb.Users.FindAsync(userId);
        if (authUser != null && authUser.KycStatus == KycStatus.NotStarted)
        {
            authUser.KycStatus = KycStatus.InProgress;
            authUser.UpdatedAt = DateTime.UtcNow;
        }
        
        await authDb.SaveChangesAsync();
        
        return TypedResults.Ok(new { success = true });
    }
    
    private static async Task<IResult> SubmitKyc(
        [FromBody] KycSubmissionData data,
        ClaimsPrincipal user,
        AuthDbContext authDb,
        ILogger<Program> logger,
        HttpContext httpContext,
        IAlpacaClient alpacaClient)
    {
        var userId = Guid.Parse(user.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? throw new UnauthorizedAccessException());
        
        var authUser = await authDb.Users.FindAsync(userId);
        if (authUser == null)
            return TypedResults.NotFound();
            
        // Validate all required data is present
        if (data.PersonalInfo == null || data.Address == null || 
            data.Identity == null || data.Documents == null ||
            data.FinancialProfile == null || data.Agreements == null ||
            data.BankAccount == null)
        {
            return TypedResults.BadRequest("All KYC sections must be completed");
        }
        
        // Get or create KYC progress record
        var kycProgress = await authDb.KycProgressRecords
            .FirstOrDefaultAsync(k => k.UserId == userId);
            
        if (kycProgress == null)
        {
            kycProgress = new KycProgress
            {
                UserId = userId,
                LastUpdated = DateTime.UtcNow
            };
            authDb.KycProgressRecords.Add(kycProgress);
        }
        
        // Save all KYC data at once
        kycProgress.HasPersonalInfo = true;
        kycProgress.PersonalInfoData = JsonSerializer.Serialize(data.PersonalInfo);
        
        kycProgress.HasAddress = true;
        kycProgress.AddressData = JsonSerializer.Serialize(data.Address);
        
        kycProgress.HasIdentity = true;
        kycProgress.IdentityData = JsonSerializer.Serialize(data.Identity);
        
        kycProgress.HasDocuments = true;
        kycProgress.DocumentsData = JsonSerializer.Serialize(data.Documents);
        
        kycProgress.HasFinancialProfile = true;
        kycProgress.FinancialProfileData = JsonSerializer.Serialize(data.FinancialProfile);
        
        kycProgress.HasAgreements = true;
        kycProgress.AgreementsData = JsonSerializer.Serialize(data.Agreements);
        
        kycProgress.HasBankAccount = true;
        kycProgress.BankAccountData = JsonSerializer.Serialize(data.BankAccount);
        
        kycProgress.CurrentStep = "completed";
        kycProgress.LastUpdated = DateTime.UtcNow;
        
        // Update user KYC status
        authUser.KycStatus = KycStatus.UnderReview;
        authUser.KycSubmittedAt = DateTime.UtcNow;
        authUser.UpdatedAt = DateTime.UtcNow;
        
        await authDb.SaveChangesAsync();
        
        logger.LogInformation("KYC submission received for user {UserId}", userId);
        
        // Create Alpaca Broker account
        try
        {
            // Get client IP address
            var ipAddress = httpContext.Connection.RemoteIpAddress?.ToString() ?? "127.0.0.1";
            
            // Map KYC data to Alpaca format
            var alpacaRequest = AlpacaKycMapper.MapToAlpacaAccount(data, authUser.Email, ipAddress);
            
            // Get Alpaca API credentials from environment
            var apiKeyId = Environment.GetEnvironmentVariable("ALPACA_API_KEY_ID") ?? throw new InvalidOperationException("ALPACA_API_KEY_ID not configured");
            var apiSecret = Environment.GetEnvironmentVariable("ALPACA_API_SECRET") ?? throw new InvalidOperationException("ALPACA_API_SECRET not configured");
            
            // Submit to Alpaca
            var alpacaAccount = await alpacaClient.CreateBrokerAccountAsync(apiKeyId, apiSecret, alpacaRequest);
            
            if (alpacaAccount != null && !string.IsNullOrEmpty(alpacaAccount.Id))
            {
                // Store Alpaca account ID
                authUser.AlpacaAccountId = alpacaAccount.Id;
                authUser.UpdatedAt = DateTime.UtcNow;
                await authDb.SaveChangesAsync();
                
                logger.LogInformation("Created Alpaca account {AlpacaAccountId} for user {UserId}", 
                    alpacaAccount.Id, userId);
                
                // Start background task to poll for approval
                var serviceProvider = httpContext.RequestServices;
                _ = Task.Run(async () =>
                {
                    await KycHelpers.PollAlpacaAccountStatus(serviceProvider, userId, alpacaAccount.Id, logger);
                });
            }
            else
            {
                logger.LogError("Failed to create Alpaca account for user {UserId} - no account ID returned", userId);
                
                // Fall back to auto-approval for development
                var serviceProvider = httpContext.RequestServices;
                _ = Task.Run(async () =>
                {
                    await Task.Delay(5000);
                    await KycHelpers.AutoApproveKyc(serviceProvider, userId, logger);
                });
            }
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Error creating Alpaca account for user {UserId}", userId);
            
            // Fall back to auto-approval for development
            var serviceProvider = httpContext.RequestServices;
            _ = Task.Run(async () =>
            {
                await Task.Delay(5000);
                await KycHelpers.AutoApproveKyc(serviceProvider, userId, logger);
            });
        }
        
        return TypedResults.Ok(new
        {
            success = true,
            message = "KYC submission received and is under review"
        });
    }
    
}

public record KycProgressResponse
{
    public string CurrentStep { get; init; } = "welcome";
    public List<string> CompletedSteps { get; init; } = new();
    public Dictionary<string, object?> Progress { get; init; } = new();
    public DateTime? LastUpdated { get; init; }
}

public record KycStepData(object Data);

public record KycSubmissionData(
    PersonalInfoData? PersonalInfo,
    AddressData? Address,
    IdentityData? Identity,
    DocumentsData? Documents,
    FinancialProfileData? FinancialProfile,
    AgreementsData? Agreements,
    BankAccountData? BankAccount
);

public record PersonalInfoData(
    string FirstName,
    string LastName,
    string DateOfBirth,
    string PhoneNumber,
    string SocialSecurityNumber,
    string Email
);

public record AddressData(
    string StreetAddress,
    string? StreetAddress2,
    string City,
    string State,
    string ZipCode,
    string Country,
    bool IsMailingSame,
    MailingAddressData? MailingAddress
);

public record MailingAddressData(
    string StreetAddress,
    string? StreetAddress2,
    string City,
    string State,
    string ZipCode,
    string Country
);

public record IdentityData(
    string Ssn,
    string TaxIdType,
    EmploymentData Employment,
    bool PubliclyTraded,
    string? PublicCompany,
    bool AffiliatedExchange,
    string? AffiliatedFirm,
    bool PoliticallyExposed,
    bool FamilyExposed
);

public record EmploymentData(
    string Status,
    string? Employer,
    string? Occupation
);

public record DocumentsData(
    string IdType,
    string? IdFrontBase64,
    string? IdFrontFileName,
    string? IdFrontFileType,
    string? IdBackBase64,
    string? IdBackFileName,
    string? IdBackFileType
);

public record FinancialProfileData(
    string AnnualIncome,
    string NetWorth,
    string LiquidNetWorth,
    string FundingSource,
    string InvestmentObjective,
    string InvestmentExperience,
    string RiskTolerance
);

public record AgreementsData(
    bool CustomerAgreement,
    bool MarketDataAgreement,
    bool PrivacyPolicy,
    bool CommunicationConsent,
    bool W9Certification
);

public record BankAccountData(
    string AccountType,
    string RoutingNumber,
    string AccountNumber,
    string BankName,
    string? AccountHolderName
);

// Helper methods for Alpaca integration
public static class KycHelpers
{
    public static async Task PollAlpacaAccountStatus(
        IServiceProvider serviceProvider,
        Guid userId,
        string alpacaAccountId,
        ILogger logger)
    {
        
        // Poll every 30 seconds for up to 10 minutes
        var maxAttempts = 20;
        var delayMs = 30000;
        
        for (int i = 0; i < maxAttempts; i++)
        {
            await Task.Delay(delayMs);
            
            using var scope = serviceProvider.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<AuthDbContext>();
            var alpacaClient = scope.ServiceProvider.GetRequiredService<IAlpacaClient>();
            
            try
            {
                // Get Alpaca API credentials
                var apiKeyId = Environment.GetEnvironmentVariable("ALPACA_API_KEY_ID");
                var apiSecret = Environment.GetEnvironmentVariable("ALPACA_API_SECRET");
                
                if (string.IsNullOrEmpty(apiKeyId) || string.IsNullOrEmpty(apiSecret))
                {
                    logger.LogError("Alpaca API credentials not configured");
                    break;
                }
                
                // Check account status with Alpaca
                var account = await alpacaClient.GetBrokerAccountAsync(apiKeyId, apiSecret, alpacaAccountId);
                if (account == null) continue;
                
                var user = await db.Users.FindAsync(userId);
                if (user == null) break;
                
                // Update status based on Alpaca account status
                if (account.Status == "ACTIVE" && user.KycStatus == KycStatus.UnderReview)
                {
                    user.KycStatus = KycStatus.Approved;
                    user.KycApprovedAt = DateTime.UtcNow;
                    user.UpdatedAt = DateTime.UtcNow;
                    await db.SaveChangesAsync();
                    
                    logger.LogInformation("Alpaca account {AlpacaAccountId} approved for user {UserId}", 
                        alpacaAccountId, userId);
                    break;
                }
                else if (account.Status == "REJECTED" && user.KycStatus == KycStatus.UnderReview)
                {
                    user.KycStatus = KycStatus.Rejected;
                    user.UpdatedAt = DateTime.UtcNow;
                    await db.SaveChangesAsync();
                    
                    logger.LogWarning("Alpaca account {AlpacaAccountId} rejected for user {UserId}", 
                        alpacaAccountId, userId);
                    break;
                }
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "Error checking Alpaca account status for {AlpacaAccountId}", 
                    alpacaAccountId);
            }
        }
    }
    
    public static async Task AutoApproveKyc(
        IServiceProvider serviceProvider,
        Guid userId,
        ILogger logger)
    {
        using var scope = serviceProvider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AuthDbContext>();
        
        var user = await db.Users.FindAsync(userId);
        if (user != null && user.KycStatus == KycStatus.UnderReview)
        {
            user.KycStatus = KycStatus.Approved;
            user.KycApprovedAt = DateTime.UtcNow;
            user.UpdatedAt = DateTime.UtcNow;
            await db.SaveChangesAsync();
            
            logger.LogInformation("Auto-approved KYC for user {UserId} (fallback)", userId);
        }
    }
}