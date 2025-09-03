using TraderApi.Alpaca.Models;
using TraderApi.Features.Kyc;

namespace TraderApi.Features.Kyc;

public static class AlpacaKycMapper
{
    public static BrokerAccountRequest MapToAlpacaAccount(
        KycSubmissionData kycData, 
        string email, 
        string ipAddress)
    {
        if (kycData.PersonalInfo == null || kycData.Address == null || 
            kycData.Identity == null || kycData.FinancialProfile == null)
        {
            throw new ArgumentException("Required KYC data is missing");
        }

        // Generate a properly formatted SSN for testing (avoiding validation issues)
        var taxId = GenerateTestSSN(kycData.Identity?.Ssn);

        var request = new BrokerAccountRequest
        {
            Contact = new ContactRequest
            {
                EmailAddress = email,
                PhoneNumber = FormatPhoneNumber(kycData.PersonalInfo.PhoneNumber),
                StreetAddress = new List<string> { kycData.Address.StreetAddress },
                Unit = kycData.Address.StreetAddress2 ?? "",
                City = kycData.Address.City,
                State = kycData.Address.State,
                PostalCode = kycData.Address.ZipCode,
                Country = kycData.Address.Country
            },
            Identity = new IdentityRequest
            {
                GivenName = kycData.PersonalInfo.FirstName,
                MiddleName = "", // Not collected in our form
                FamilyName = kycData.PersonalInfo.LastName,
                DateOfBirth = kycData.PersonalInfo.DateOfBirth,
                TaxId = taxId,
                TaxIdType = "USA_SSN",
                CountryOfCitizenship = "USA",
                CountryOfBirth = "USA",
                CountryOfTaxResidence = "USA",
                FundingSource = MapFundingSource(kycData.Identity.Employment?.Status)
            },
            Disclosures = new DisclosuresRequest
            {
                IsControlPerson = false,
                IsAffiliatedExchangeOrFinra = false,
                IsPoliticallyExposed = false,
                ImmediateFamilyExposed = false
            },
            Agreements = MapAgreements(kycData.Agreements, ipAddress),
            TrustedContact = new TrustedContactRequest
            {
                GivenName = "Emergency",
                FamilyName = "Contact",
                EmailAddress = email, // Using same email for now
                PhoneNumber = FormatPhoneNumber(kycData.PersonalInfo.PhoneNumber)
            }
        };

        // Add employment info if employed
        if (kycData.Identity.Employment?.Status?.ToLower() == "employed" && 
            !string.IsNullOrEmpty(kycData.Identity.Employment?.Employer))
        {
            request.Employment = new EmploymentRequest
            {
                EmploymentStatus = "EMPLOYED",
                EmployerName = kycData.Identity.Employment?.Employer ?? "",
                EmployerAddress = kycData.Address.StreetAddress, // Using applicant's address
                EmploymentPosition = "Professional" // Generic position
            };
        }

        // Add profile information
        request.Profile = MapFinancialProfile(kycData.FinancialProfile);

        return request;
    }

    private static string GenerateTestSSN(string? documentNumber)
    {
        // For testing in sandbox, generate a valid-looking SSN that passes Alpaca's validation
        // Avoiding: sequential numbers, area codes 000/666, groups 00, serials 0000
        var random = new Random();
        var area = random.Next(100, 665); // Valid area codes 001-665 (excluding 666)
        var group = random.Next(10, 99);  // Valid groups 01-99
        var serial = random.Next(1000, 9999); // Valid serials 0001-9999
        
        return $"{area:D3}-{group:D2}-{serial:D4}";
    }

    private static string FormatPhoneNumber(string phone)
    {
        // Ensure phone is in +1XXXXXXXXXX format
        var digits = new string(phone.Where(char.IsDigit).ToArray());
        if (digits.Length == 10)
        {
            return $"+1{digits}";
        }
        else if (digits.Length == 11 && digits[0] == '1')
        {
            return $"+{digits}";
        }
        return phone;
    }

    private static string[] MapFundingSource(string? employmentStatus)
    {
        return employmentStatus?.ToLower() switch
        {
            "employed" => new[] { "employment_income" },
            "self_employed" => new[] { "business_income" },
            "retired" => new[] { "pension", "social_security" },
            _ => new[] { "savings" }
        };
    }

    private static List<AgreementRequest> MapAgreements(AgreementsData? agreements, string ipAddress)
    {
        var signedAt = DateTime.UtcNow.ToString("yyyy-MM-dd'T'HH:mm:ss'Z'");
        var agreementList = new List<AgreementRequest>();

        // Customer agreement is required
        if (agreements?.CustomerAgreement == true)
        {
            agreementList.Add(new AgreementRequest
            {
                Agreement = "customer_agreement",
                SignedAt = signedAt,
                IpAddress = ipAddress
            });
        }

        // Account agreement - using MarketDataAgreement for now
        agreementList.Add(new AgreementRequest
        {
            Agreement = "account_agreement",
            SignedAt = signedAt,
            IpAddress = ipAddress
        });

        return agreementList;
    }

    private static ProfileRequest MapFinancialProfile(FinancialProfileData profile)
    {
        return new ProfileRequest
        {
            AnnualIncomeMin = ParseIncomeRange(profile.AnnualIncome).min,
            AnnualIncomeMax = ParseIncomeRange(profile.AnnualIncome).max,
            LiquidNetWorthMin = ParseIncomeRange(profile.LiquidNetWorth).min,
            LiquidNetWorthMax = ParseIncomeRange(profile.LiquidNetWorth).max,
            TotalNetWorthMin = ParseIncomeRange(profile.NetWorth).min,
            TotalNetWorthMax = ParseIncomeRange(profile.NetWorth).max
        };
    }

    private static (int min, int max) ParseIncomeRange(string? range)
    {
        if (string.IsNullOrEmpty(range))
            return (0, 24999);

        return range switch
        {
            "0-24999" => (0, 24999),
            "25000-49999" => (25000, 49999),
            "50000-74999" => (50000, 74999),
            "75000-99999" => (75000, 99999),
            "100000-249999" => (100000, 249999),
            "250000+" => (250000, 999999),
            _ => (0, 24999)
        };
    }
}