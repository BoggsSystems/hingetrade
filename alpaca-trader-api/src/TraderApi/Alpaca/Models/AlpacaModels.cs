using System.Text.Json.Serialization;

namespace TraderApi.Alpaca.Models;

public class AlpacaAccount
{
    [JsonPropertyName("account_number")]
    public string AccountNumber { get; set; } = default!;
    
    [JsonPropertyName("status")]
    public string Status { get; set; } = default!;
    
    [JsonPropertyName("cash")]
    public decimal Cash { get; set; }
    
    [JsonPropertyName("portfolio_value")]
    public decimal PortfolioValue { get; set; }
    
    [JsonPropertyName("pattern_day_trader")]
    public bool PatternDayTrader { get; set; }
    
    [JsonPropertyName("trading_blocked")]
    public bool TradingBlocked { get; set; }
    
    [JsonPropertyName("transfers_blocked")]
    public bool TransfersBlocked { get; set; }
    
    [JsonPropertyName("account_blocked")]
    public bool AccountBlocked { get; set; }
    
    [JsonPropertyName("buying_power")]
    public decimal BuyingPower { get; set; }
}

public class AlpacaPosition
{
    [JsonPropertyName("asset_id")]
    public string AssetId { get; set; } = default!;
    
    [JsonPropertyName("symbol")]
    public string Symbol { get; set; } = default!;
    
    [JsonPropertyName("exchange")]
    public string Exchange { get; set; } = default!;
    
    [JsonPropertyName("asset_class")]
    public string AssetClass { get; set; } = default!;
    
    [JsonPropertyName("qty")]
    public decimal Qty { get; set; }
    
    [JsonPropertyName("avg_entry_price")]
    public decimal AvgEntryPrice { get; set; }
    
    [JsonPropertyName("side")]
    public string Side { get; set; } = default!;
    
    [JsonPropertyName("market_value")]
    public decimal MarketValue { get; set; }
    
    [JsonPropertyName("cost_basis")]
    public decimal CostBasis { get; set; }
    
    [JsonPropertyName("unrealized_pl")]
    public decimal UnrealizedPl { get; set; }
    
    [JsonPropertyName("unrealized_plpc")]
    public decimal UnrealizedPlpc { get; set; }
    
    [JsonPropertyName("current_price")]
    public decimal CurrentPrice { get; set; }
}

public class AlpacaOrder
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = default!;
    
    [JsonPropertyName("client_order_id")]
    public string ClientOrderId { get; set; } = default!;
    
    [JsonPropertyName("created_at")]
    public DateTime CreatedAt { get; set; }
    
    [JsonPropertyName("updated_at")]
    public DateTime? UpdatedAt { get; set; }
    
    [JsonPropertyName("submitted_at")]
    public DateTime? SubmittedAt { get; set; }
    
    [JsonPropertyName("filled_at")]
    public DateTime? FilledAt { get; set; }
    
    [JsonPropertyName("expired_at")]
    public DateTime? ExpiredAt { get; set; }
    
    [JsonPropertyName("canceled_at")]
    public DateTime? CanceledAt { get; set; }
    
    [JsonPropertyName("failed_at")]
    public DateTime? FailedAt { get; set; }
    
    [JsonPropertyName("asset_id")]
    public string AssetId { get; set; } = default!;
    
    [JsonPropertyName("symbol")]
    public string Symbol { get; set; } = default!;
    
    [JsonPropertyName("asset_class")]
    public string AssetClass { get; set; } = default!;
    
    [JsonPropertyName("qty")]
    public decimal Qty { get; set; }
    
    [JsonPropertyName("filled_qty")]
    public decimal FilledQty { get; set; }
    
    [JsonPropertyName("type")]
    public string Type { get; set; } = default!;
    
    [JsonPropertyName("side")]
    public string Side { get; set; } = default!;
    
    [JsonPropertyName("time_in_force")]
    public string TimeInForce { get; set; } = default!;
    
    [JsonPropertyName("limit_price")]
    public decimal? LimitPrice { get; set; }
    
    [JsonPropertyName("stop_price")]
    public decimal? StopPrice { get; set; }
    
    [JsonPropertyName("filled_avg_price")]
    public decimal? FilledAvgPrice { get; set; }
    
    [JsonPropertyName("status")]
    public string Status { get; set; } = default!;
    
    [JsonPropertyName("extended_hours")]
    public bool ExtendedHours { get; set; }
}

public class AlpacaOrderRequest
{
    [JsonPropertyName("symbol")]
    public string Symbol { get; set; } = default!;
    
    [JsonPropertyName("qty")]
    public decimal? Qty { get; set; }
    
    [JsonPropertyName("notional")]
    public decimal? Notional { get; set; }
    
    [JsonPropertyName("side")]
    public string Side { get; set; } = default!;
    
    [JsonPropertyName("type")]
    public string Type { get; set; } = default!;
    
    [JsonPropertyName("time_in_force")]
    public string TimeInForce { get; set; } = default!;
    
    [JsonPropertyName("limit_price")]
    public decimal? LimitPrice { get; set; }
    
    [JsonPropertyName("stop_price")]
    public decimal? StopPrice { get; set; }
    
    [JsonPropertyName("client_order_id")]
    public string ClientOrderId { get; set; } = default!;
    
    [JsonPropertyName("extended_hours")]
    public bool? ExtendedHours { get; set; }
}

public class AlpacaQuote
{
    [JsonPropertyName("S")]
    public string Symbol { get; set; } = default!;
    
    [JsonPropertyName("ap")]
    public decimal AskPrice { get; set; }
    
    [JsonPropertyName("as")]
    public int AskSize { get; set; }
    
    [JsonPropertyName("bp")]
    public decimal BidPrice { get; set; }
    
    [JsonPropertyName("bs")]
    public int BidSize { get; set; }
    
    [JsonPropertyName("t")]
    public DateTime Timestamp { get; set; }
}

public class AlpacaBar
{
    [JsonPropertyName("S")]
    public string Symbol { get; set; } = default!;
    
    [JsonPropertyName("o")]
    public decimal Open { get; set; }
    
    [JsonPropertyName("h")]
    public decimal High { get; set; }
    
    [JsonPropertyName("l")]
    public decimal Low { get; set; }
    
    [JsonPropertyName("c")]
    public decimal Close { get; set; }
    
    [JsonPropertyName("v")]
    public long Volume { get; set; }
    
    [JsonPropertyName("t")]
    public DateTime Timestamp { get; set; }
}

public class AlpacaWebhookPayload
{
    [JsonPropertyName("event")]
    public string Event { get; set; } = default!;
    
    [JsonPropertyName("timestamp")]
    public DateTime Timestamp { get; set; }
    
    [JsonPropertyName("order")]
    public AlpacaOrder? Order { get; set; }
    
    [JsonPropertyName("account")]
    public AlpacaAccount? Account { get; set; }
}

public class BrokerAccount
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = default!;
    
    [JsonPropertyName("account_number")]
    public string AccountNumber { get; set; } = default!;
    
    [JsonPropertyName("status")]
    public string Status { get; set; } = default!;
    
    [JsonPropertyName("currency")]
    public string Currency { get; set; } = default!;
    
    [JsonPropertyName("last_equity")]
    public string LastEquity { get; set; } = default!;
    
    [JsonPropertyName("created_at")]
    public DateTime CreatedAt { get; set; }
}

public class BrokerAccountRequest
{
    [JsonPropertyName("contact")]
    public ContactRequest Contact { get; set; } = default!;
    
    [JsonPropertyName("identity")]
    public IdentityRequest Identity { get; set; } = default!;
    
    [JsonPropertyName("disclosures")]
    public DisclosuresRequest Disclosures { get; set; } = default!;
    
    [JsonPropertyName("agreements")]
    public List<AgreementRequest> Agreements { get; set; } = new();
    
    [JsonPropertyName("documents")]
    public List<object>? Documents { get; set; }
    
    [JsonPropertyName("trusted_contact")]
    public TrustedContactRequest? TrustedContact { get; set; }
    
    [JsonPropertyName("employment")]
    public EmploymentRequest? Employment { get; set; }
    
    [JsonPropertyName("profile")]
    public ProfileRequest? Profile { get; set; }
}

public class ContactRequest
{
    [JsonPropertyName("email_address")]
    public string EmailAddress { get; set; } = default!;
    
    [JsonPropertyName("phone_number")]
    public string PhoneNumber { get; set; } = default!;
    
    [JsonPropertyName("street_address")]
    public List<string> StreetAddress { get; set; } = new();
    
    [JsonPropertyName("city")]
    public string City { get; set; } = default!;
    
    [JsonPropertyName("state")]
    public string State { get; set; } = default!;
    
    [JsonPropertyName("postal_code")]
    public string PostalCode { get; set; } = default!;
    
    [JsonPropertyName("country")]
    public string Country { get; set; } = "USA";
    
    [JsonPropertyName("unit")]
    public string? Unit { get; set; }
}

public class IdentityRequest
{
    [JsonPropertyName("given_name")]
    public string GivenName { get; set; } = default!;
    
    [JsonPropertyName("middle_name")]
    public string? MiddleName { get; set; }
    
    [JsonPropertyName("family_name")]
    public string FamilyName { get; set; } = default!;
    
    [JsonPropertyName("date_of_birth")]
    public string DateOfBirth { get; set; } = default!;
    
    [JsonPropertyName("tax_id")]
    public string TaxId { get; set; } = default!;
    
    [JsonPropertyName("tax_id_type")]
    public string TaxIdType { get; set; } = "USA_SSN";
    
    [JsonPropertyName("country_of_citizenship")]
    public string CountryOfCitizenship { get; set; } = "USA";
    
    [JsonPropertyName("country_of_birth")]
    public string CountryOfBirth { get; set; } = "USA";
    
    [JsonPropertyName("country_of_tax_residence")]
    public string CountryOfTaxResidence { get; set; } = "USA";
    
    [JsonPropertyName("funding_source")]
    public string[] FundingSource { get; set; } = new[] { "employment_income" };
}

public class AgreementRequest
{
    [JsonPropertyName("agreement")]
    public string Agreement { get; set; } = default!;
    
    [JsonPropertyName("signed_at")]
    public string SignedAt { get; set; } = default!;
    
    [JsonPropertyName("ip_address")]
    public string IpAddress { get; set; } = default!;
}

public class DisclosuresRequest
{
    [JsonPropertyName("is_control_person")]
    public bool IsControlPerson { get; set; }
    
    [JsonPropertyName("is_affiliated_exchange_or_finra")]
    public bool IsAffiliatedExchangeOrFinra { get; set; }
    
    [JsonPropertyName("is_politically_exposed")]
    public bool IsPoliticallyExposed { get; set; }
    
    [JsonPropertyName("immediate_family_exposed")]
    public bool ImmediateFamilyExposed { get; set; }
}

public class TrustedContactRequest
{
    [JsonPropertyName("given_name")]
    public string GivenName { get; set; } = default!;
    
    [JsonPropertyName("family_name")]
    public string FamilyName { get; set; } = default!;
    
    [JsonPropertyName("email_address")]
    public string EmailAddress { get; set; } = default!;
    
    [JsonPropertyName("phone_number")]
    public string PhoneNumber { get; set; } = default!;
}

public class EmploymentRequest
{
    [JsonPropertyName("employment_status")]
    public string EmploymentStatus { get; set; } = default!;
    
    [JsonPropertyName("employer_name")]
    public string? EmployerName { get; set; }
    
    [JsonPropertyName("employer_address")]
    public string? EmployerAddress { get; set; }
    
    [JsonPropertyName("employment_position")]
    public string? EmploymentPosition { get; set; }
}

public class ProfileRequest
{
    [JsonPropertyName("annual_income_min")]
    public int AnnualIncomeMin { get; set; }
    
    [JsonPropertyName("annual_income_max")]
    public int AnnualIncomeMax { get; set; }
    
    [JsonPropertyName("liquid_net_worth_min")]
    public int LiquidNetWorthMin { get; set; }
    
    [JsonPropertyName("liquid_net_worth_max")]
    public int LiquidNetWorthMax { get; set; }
    
    [JsonPropertyName("total_net_worth_min")]
    public int TotalNetWorthMin { get; set; }
    
    [JsonPropertyName("total_net_worth_max")]
    public int TotalNetWorthMax { get; set; }
}

// Funding Models
public class BankRelationship
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = default!;
    
    [JsonPropertyName("account_id")]
    public string AccountId { get; set; } = default!;
    
    [JsonPropertyName("status")]
    public string Status { get; set; } = default!;
    
    [JsonPropertyName("account_owner_name")]
    public string AccountOwnerName { get; set; } = default!;
    
    [JsonPropertyName("bank_account_type")]
    public string BankAccountType { get; set; } = default!;
    
    [JsonPropertyName("bank_account_number")]
    public string BankAccountNumber { get; set; } = default!;
    
    [JsonPropertyName("bank_routing_number")]
    public string BankRoutingNumber { get; set; } = default!;
    
    [JsonPropertyName("nickname")]
    public string? Nickname { get; set; }
    
    [JsonPropertyName("created_at")]
    public DateTime CreatedAt { get; set; }
    
    [JsonPropertyName("updated_at")]
    public DateTime UpdatedAt { get; set; }
}

public class AlpacaAchTransferRequest
{
    [JsonPropertyName("amount")]
    public string Amount { get; set; } = default!;
    
    [JsonPropertyName("direction")]
    public string Direction { get; set; } = default!; // INCOMING or OUTGOING
    
    [JsonPropertyName("relationship_id")]
    public string RelationshipId { get; set; } = default!;
    
    [JsonPropertyName("transfer_type")]
    public string TransferType { get; set; } = "ach";
}

public class AchTransfer
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = default!;
    
    [JsonPropertyName("status")]
    public string Status { get; set; } = default!;
    
    [JsonPropertyName("amount")]
    public string Amount { get; set; } = default!;
    
    [JsonPropertyName("direction")]
    public string Direction { get; set; } = default!;
    
    [JsonPropertyName("created_at")]
    public DateTime CreatedAt { get; set; }
    
    [JsonPropertyName("updated_at")]
    public DateTime UpdatedAt { get; set; }
}

public class Transfer
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = default!;
    
    [JsonPropertyName("account_id")]
    public string AccountId { get; set; } = default!;
    
    [JsonPropertyName("type")]
    public string Type { get; set; } = default!;
    
    [JsonPropertyName("status")]
    public string Status { get; set; } = default!;
    
    [JsonPropertyName("amount")]
    public string Amount { get; set; } = default!;
    
    [JsonPropertyName("direction")]
    public string Direction { get; set; } = default!;
    
    [JsonPropertyName("relationship_id")]
    public string? RelationshipId { get; set; }
    
    [JsonPropertyName("reason")]
    public string? Reason { get; set; }
    
    [JsonPropertyName("created_at")]
    public DateTime CreatedAt { get; set; }
    
    [JsonPropertyName("updated_at")]
    public DateTime UpdatedAt { get; set; }
    
    [JsonPropertyName("expires_at")]
    public DateTime? ExpiresAt { get; set; }
}