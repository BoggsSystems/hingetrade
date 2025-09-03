using System.Text.Json.Serialization;

namespace TraderApi.Features.Funding.Models;

// Plaid Link Token Response
public class PlaidLinkTokenResponse
{
    [JsonPropertyName("link_token")]
    public string LinkToken { get; set; } = default!;
    
    [JsonPropertyName("expiration")]
    public DateTime Expiration { get; set; }
    
    [JsonPropertyName("request_id")]
    public string RequestId { get; set; } = default!;
}

// Plaid Token Exchange Response
public class PlaidTokenExchangeResponse
{
    [JsonPropertyName("access_token")]
    public string AccessToken { get; set; } = default!;
    
    [JsonPropertyName("item_id")]
    public string ItemId { get; set; } = default!;
    
    [JsonPropertyName("request_id")]
    public string RequestId { get; set; } = default!;
}

// Plaid Processor Token Response
public class PlaidProcessorTokenResponse
{
    [JsonPropertyName("processor_token")]
    public string ProcessorToken { get; set; } = default!;
    
    [JsonPropertyName("request_id")]
    public string RequestId { get; set; } = default!;
}

// Plaid Account
public class PlaidAccount
{
    [JsonPropertyName("account_id")]
    public string AccountId { get; set; } = default!;
    
    [JsonPropertyName("balances")]
    public PlaidBalance Balances { get; set; } = default!;
    
    [JsonPropertyName("mask")]
    public string Mask { get; set; } = default!;
    
    [JsonPropertyName("name")]
    public string Name { get; set; } = default!;
    
    [JsonPropertyName("official_name")]
    public string? OfficialName { get; set; }
    
    [JsonPropertyName("subtype")]
    public string Subtype { get; set; } = default!;
    
    [JsonPropertyName("type")]
    public string Type { get; set; } = default!;
}

// Plaid Balance
public class PlaidBalance
{
    [JsonPropertyName("available")]
    public decimal? Available { get; set; }
    
    [JsonPropertyName("current")]
    public decimal Current { get; set; }
    
    [JsonPropertyName("iso_currency_code")]
    public string IsoCurrencyCode { get; set; } = default!;
    
    [JsonPropertyName("limit")]
    public decimal? Limit { get; set; }
}

// Plaid Error
public class PlaidError
{
    [JsonPropertyName("error_type")]
    public string ErrorType { get; set; } = default!;
    
    [JsonPropertyName("error_code")]
    public string ErrorCode { get; set; } = default!;
    
    [JsonPropertyName("error_message")]
    public string ErrorMessage { get; set; } = default!;
    
    [JsonPropertyName("display_message")]
    public string? DisplayMessage { get; set; }
}

// Frontend request models
public class PlaidLinkRequest
{
    public string UserId { get; set; } = default!;
    public string UserEmail { get; set; } = default!;
}

public class PlaidTokenExchangeRequest
{
    public string PublicToken { get; set; } = default!;
}

public class PlaidProcessorTokenRequest
{
    public string PublicToken { get; set; } = default!;
    public string AccountId { get; set; } = default!;
}

// Alpaca ACH Relationship Request using Plaid
public class AlpacaAchRelationshipRequest
{
    [JsonPropertyName("account_owner_name")]
    public string AccountOwnerName { get; set; } = default!;
    
    [JsonPropertyName("bank_account_type")]
    public string BankAccountType { get; set; } = default!; // CHECKING or SAVINGS
    
    [JsonPropertyName("bank_account_number")]
    public string? BankAccountNumber { get; set; }
    
    [JsonPropertyName("bank_routing_number")]
    public string? BankRoutingNumber { get; set; }
    
    [JsonPropertyName("processor_token")]
    public string? ProcessorToken { get; set; }
    
    [JsonPropertyName("ach_processor")]
    public string? AchProcessor { get; set; } = "plaid";
}