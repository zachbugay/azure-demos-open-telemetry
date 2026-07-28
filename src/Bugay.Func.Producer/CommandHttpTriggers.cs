using System;
using System.Net;
using System.Text.Json;
using System.Threading.Tasks;
using Azure.Messaging.ServiceBus;
using Bugay.Func.Contracts;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.WebJobs.Extensions.OpenApi.Core.Attributes;
using Microsoft.Azure.WebJobs.Extensions.OpenApi.Core.Enums;
using Microsoft.Extensions.Logging;

namespace Bugay.Func.Producer;

/// <summary>
/// HTTP endpoints that accept create requests and publish a command envelope to the
/// shared Service Bus queue. Identifiers are generated here (client-supplied keys) so
/// callers can reference the created entities immediately.
/// </summary>
public class CommandHttpTriggers
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

    private readonly ServiceBusSender _sender;
    private readonly ILogger<CommandHttpTriggers> _logger;

    public CommandHttpTriggers(ServiceBusSender sender, ILogger<CommandHttpTriggers> logger)
    {
        _sender = sender;
        _logger = logger;
    }

    public sealed record CreateUserRequest(string FirstName, string LastName);
    public sealed record CreateAccountRequest(Guid UserId, string? Name);
    public sealed record CreateTransactionRequest(Guid AccountId, decimal Amount);

    [Function("CreateUser")]
    [OpenApiOperation(operationId: "createUser", tags: new[] { "users" }, Summary = "Create a user", Visibility = OpenApiVisibilityType.Important)]
    [OpenApiRequestBody(contentType: "application/json", bodyType: typeof(CreateUserRequest), Required = true)]
    [OpenApiResponseWithBody(statusCode: HttpStatusCode.Accepted, contentType: "application/json", bodyType: typeof(CreateUserCommand))]
    public async Task<IActionResult> CreateUser(
        [HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = "users")] HttpRequest req)
    {
        var request = await ReadBodyAsync<CreateUserRequest>(req);
        if (request is null || string.IsNullOrWhiteSpace(request.FirstName) || string.IsNullOrWhiteSpace(request.LastName))
        {
            return new BadRequestObjectResult("FirstName and LastName are required.");
        }

        var command = new CreateUserCommand(Guid.NewGuid(), request.FirstName, request.LastName);
        await PublishAsync(CommandEnvelope.Wrap(command));

        _logger.LogInformation("Published CreateUser command for {UserId}", command.Id);
        return new AcceptedResult(string.Empty, command);
    }

    [Function("CreateAccount")]
    [OpenApiOperation(operationId: "createAccount", tags: new[] { "accounts" }, Summary = "Create an account", Visibility = OpenApiVisibilityType.Important)]
    [OpenApiRequestBody(contentType: "application/json", bodyType: typeof(CreateAccountRequest), Required = true)]
    [OpenApiResponseWithBody(statusCode: HttpStatusCode.Accepted, contentType: "application/json", bodyType: typeof(CreateAccountCommand))]
    public async Task<IActionResult> CreateAccount(
        [HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = "accounts")] HttpRequest req)
    {
        var request = await ReadBodyAsync<CreateAccountRequest>(req);
        if (request is null || request.UserId == Guid.Empty)
        {
            return new BadRequestObjectResult("A non-empty UserId is required.");
        }

        var command = new CreateAccountCommand(Guid.NewGuid(), request.UserId, request.Name);
        await PublishAsync(CommandEnvelope.Wrap(command));

        _logger.LogInformation("Published CreateAccount command for {AccountId}", command.Id);
        return new AcceptedResult(string.Empty, command);
    }

    [Function("CreateTransaction")]
    [OpenApiOperation(operationId: "createTransaction", tags: new[] { "transactions" }, Summary = "Create a transaction", Visibility = OpenApiVisibilityType.Important)]
    [OpenApiRequestBody(contentType: "application/json", bodyType: typeof(CreateTransactionRequest), Required = true)]
    [OpenApiResponseWithBody(statusCode: HttpStatusCode.Accepted, contentType: "application/json", bodyType: typeof(CreateTransactionCommand))]
    public async Task<IActionResult> CreateTransaction(
        [HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = "transactions")] HttpRequest req)
    {
        var request = await ReadBodyAsync<CreateTransactionRequest>(req);
        if (request is null || request.AccountId == Guid.Empty)
        {
            return new BadRequestObjectResult("A non-empty AccountId is required.");
        }

        var command = new CreateTransactionCommand(Guid.NewGuid(), request.AccountId, request.Amount);
        await PublishAsync(CommandEnvelope.Wrap(command));

        _logger.LogInformation("Published CreateTransaction command for {TransactionId}", command.Id);
        return new AcceptedResult(string.Empty, command);
    }

    private static async Task<T?> ReadBodyAsync<T>(HttpRequest req) =>
        await JsonSerializer.DeserializeAsync<T>(req.Body, JsonOptions);

    private async Task PublishAsync(CommandEnvelope envelope)
    {
        var message = new ServiceBusMessage(envelope.Serialize())
        {
            Subject = envelope.Type.ToString(),
            ContentType = "application/json"
        };

        await _sender.SendMessageAsync(message);
    }
}
