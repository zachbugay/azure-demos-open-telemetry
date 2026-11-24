using Bogus;
using Bugay.Func.Contracts;
using Microsoft.Extensions.Logging;
using System;
using System.Net.Http;
using System.Net.Http.Json;
using System.Threading;
using System.Threading.Tasks;

namespace Bugay.Data.Generator;

/// <summary>
/// Uses Bogus to fabricate a batch of users, one account per user, and a random
/// number of transactions per account, then POSTs each create request to the
/// Producer API directly or through API Management so the Producer publishes the command.
///
/// Requests are sent in dependency order (user -> account -> transactions). The
/// Producer generates the identifiers, so each response is read back to obtain the
/// new id needed to build the dependent requests.
/// </summary>
public sealed class DataGenerator
{
    private const int MaxTransactionsPerAccount = 10;

    private readonly HttpClient _client;
    private readonly ILogger<DataGenerator> _logger;

    public DataGenerator(HttpClient client, ILogger<DataGenerator> logger)
    {
        _client = client;
        _logger = logger;
    }

    private sealed record CreateUserRequest(string FirstName, string LastName);
    private sealed record CreateAccountRequest(Guid UserId, string? Name);
    private sealed record CreateTransactionRequest(Guid AccountId, decimal Amount);

    public async Task GenerateAsync(int userCount, CancellationToken cancellationToken = default)
    {
        var userFaker = new Faker<CreateUserRequest>()
            .CustomInstantiator(f => new CreateUserRequest(
                f.Name.FirstName(),
                f.Name.LastName()));

        var faker = new Faker();
        var published = 0;

        for (var i = 0; i < userCount; i++)
        {
            cancellationToken.ThrowIfCancellationRequested();

            var userRequest = userFaker.Generate();
            var user = await PostAsync<CreateUserRequest, CreateUserCommand>("users", userRequest, cancellationToken);
            _logger.LogInformation("Published user {UserId} ({FirstName} {LastName})",
                user.Id, user.FirstName, user.LastName);
            published++;

            var account = await PostAsync<CreateAccountRequest, CreateAccountCommand>(
                "accounts",
                new CreateAccountRequest(user.Id, faker.Finance.AccountName()),
                cancellationToken);
            _logger.LogInformation("Published account {AccountId} for user {UserId}", account.Id, user.Id);
            published++;

            var transactionCount = faker.Random.Int(1, MaxTransactionsPerAccount);
            for (var t = 0; t < transactionCount; t++)
            {
                var amount = faker.Finance.Amount(-1_000m, 1_000m, 4);
                await PostAsync<CreateTransactionRequest, CreateTransactionCommand>(
                    "transactions",
                    new CreateTransactionRequest(account.Id, amount),
                    cancellationToken);
                published++;
            }

            _logger.LogInformation("Published {TransactionCount} transactions for account {AccountId}",
                transactionCount, account.Id);
        }

        _logger.LogInformation("Done. Published {MessageCount} command messages for {UserCount} users.",
            published, userCount);
    }

    private async Task<TResponse> PostAsync<TRequest, TResponse>(
        string path, TRequest body, CancellationToken cancellationToken)
    {
        using var response = await _client.PostAsJsonAsync(path, body, cancellationToken);
        response.EnsureSuccessStatusCode();

        return await response.Content.ReadFromJsonAsync<TResponse>(cancellationToken: cancellationToken)
            ?? throw new InvalidOperationException($"POST /{path} returned an empty response body.");
    }
}
