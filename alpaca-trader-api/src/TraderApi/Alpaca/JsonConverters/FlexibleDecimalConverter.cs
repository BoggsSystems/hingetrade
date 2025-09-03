using System.Text.Json;
using System.Text.Json.Serialization;

namespace TraderApi.Alpaca.JsonConverters;

/// <summary>
/// Handles decimal values that may be sent as strings by Alpaca Broker API
/// </summary>
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