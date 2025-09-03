using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging.Abstractions;
using TraderApi.Alpaca;
using TraderApi.Alpaca.Models;
using Xunit;

namespace TraderApi.Tests;

public class DirectHttpClientTests
{
    [Fact]
    public async Task Should_Deserialize_MockResponse_Using_AlpacaClient()
    {
        // Arrange
        var json = await File.ReadAllTextAsync("../../../MockAlpacaResponse.json");
        var mockHandler = new MockHttpMessageHandler(json);
        var httpClient = new HttpClient(mockHandler)
        {
            BaseAddress = new Uri("https://broker-api.sandbox.alpaca.markets/")
        };
        httpClient.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
        
        var settings = new AlpacaSettings
        {
            BaseUrl = "https://broker-api.sandbox.alpaca.markets/"
        };
        
        var logger = new NullLogger<AlpacaClient>();
        var alpacaClient = new AlpacaClient(httpClient, logger, settings);

        // Act
        var account = await alpacaClient.GetAccountAsync("test", "test", "920964623");

        // Assert
        Assert.NotNull(account);
        Assert.Equal("920964623", account.AccountNumber);
        Assert.Equal("ACTIVE", account.Status);
        Assert.Equal(24190.64m, account.Cash);
        Assert.Equal(24190.64m, account.PortfolioValue);
        Assert.Equal(24190.64m, account.BuyingPower);
    }
}

public class MockHttpMessageHandler : HttpMessageHandler
{
    private readonly string _responseContent;

    public MockHttpMessageHandler(string responseContent)
    {
        _responseContent = responseContent;
    }

    protected override async Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
    {
        var response = new HttpResponseMessage(HttpStatusCode.OK)
        {
            Content = new StringContent(_responseContent, Encoding.UTF8, "application/json")
        };
        
        return await Task.FromResult(response);
    }
}