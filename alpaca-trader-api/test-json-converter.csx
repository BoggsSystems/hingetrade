#!/usr/bin/env dotnet-script
#r "nuget: System.Text.Json, 9.0.0"

using System;
using System.Text.Json;
using System.Text.Json.Serialization;

public class FlexibleDecimalConverter : JsonConverter<decimal>
{
    public override decimal Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
    {
        return reader.TokenType switch
        {
            JsonTokenType.Number => reader.GetDecimal(),
            JsonTokenType.String => decimal.TryParse(reader.GetString(), out var result) ? result : 0m,
            _ => 0m
        };
    }

    public override void Write(Utf8JsonWriter writer, decimal value, JsonSerializerOptions options)
    {
        writer.WriteNumberValue(value);
    }
}

public class TestAccount
{
    [JsonPropertyName("buying_power")]
    [JsonConverter(typeof(FlexibleDecimalConverter))]
    public decimal BuyingPower { get; set; }
    
    [JsonPropertyName("cash")]
    [JsonConverter(typeof(FlexibleDecimalConverter))]
    public decimal Cash { get; set; }
}

var json = @"{""buying_power"": ""24190.64"", ""cash"": ""24190.64""}";

var options = new JsonSerializerOptions
{
    PropertyNameCaseInsensitive = true,
    Converters = { new FlexibleDecimalConverter() }
};

try
{
    var account = JsonSerializer.Deserialize<TestAccount>(json, options);
    Console.WriteLine($"BuyingPower: {account.BuyingPower}");
    Console.WriteLine($"Cash: {account.Cash}");
}
catch (Exception ex)
{
    Console.WriteLine($"Error: {ex.Message}");
}