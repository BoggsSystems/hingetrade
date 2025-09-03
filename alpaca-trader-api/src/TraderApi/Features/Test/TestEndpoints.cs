using Microsoft.AspNetCore.Http.HttpResults;
using System.Text.Json;
using TraderApi.Alpaca;
using TraderApi.Alpaca.Models;

namespace TraderApi.Features.Test;

public static class TestEndpoints
{
    public static void MapTestEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/test")
            .AllowAnonymous()
            .WithTags("Test");

        group.MapGet("/account", TestAccountDeserialization)
            .WithName("TestAccountDeserialization")
            .WithSummary("Test account JSON deserialization");
    }

    private static async Task<Results<Ok<object>, BadRequest<object>>> TestAccountDeserialization(
        IAlpacaClient alpacaClient,
        ILoggerFactory loggerFactory)
    {
        var logger = loggerFactory.CreateLogger("TestEndpoints");
        
        try 
        {
            logger.LogInformation("Testing account deserialization with mock server");
            
            var account = await alpacaClient.GetAccountAsync(
                "CKB4051UELTQZSUS78S8", 
                "ZdjZPMzxPcAf7aWngyC1UtHJfHdRjvssxIvCJTlA",
                "920964623"
            );
            
            logger.LogInformation("Successfully deserialized account: {AccountNumber}", account.AccountNumber);
            
            return TypedResults.Ok<object>(new 
            { 
                success = true,
                accountNumber = account.AccountNumber,
                cash = account.Cash,
                buyingPower = account.BuyingPower,
                status = account.Status
            });
        }
        catch (JsonException ex)
        {
            logger.LogError(ex, "JSON deserialization failed");
            return TypedResults.BadRequest<object>(new 
            { 
                error = "JsonDeserialization",
                message = ex.Message,
                innerException = ex.InnerException?.Message
            });
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Test failed");
            return TypedResults.BadRequest<object>(new 
            { 
                error = ex.GetType().Name,
                message = ex.Message
            });
        }
    }
}