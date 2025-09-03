using System.Text.Json;
using System.Text.Json.Serialization;
using TraderApi.Alpaca.JsonConverters;

namespace TraderApi.Alpaca;

public static class AlpacaJsonOptions
{
    private static readonly JsonSerializerOptions _options = CreateOptions();
    
    public static JsonSerializerOptions Default => _options;
    
    private static JsonSerializerOptions CreateOptions()
    {
        var options = new JsonSerializerOptions
        {
            PropertyNameCaseInsensitive = true,
            DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull
        };
        
        // Add converters
        options.Converters.Add(new FlexibleDecimalConverter());
        options.Converters.Add(new FlexibleNullableDecimalConverter());
        
        return options;
    }
}