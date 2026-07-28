using System;
using System.Threading;
using System.Threading.Tasks;
using Bugay.Data;
using Bugay.Data.Entities;
using Bugay.Func.Contracts;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace Bugay.Func.Consumer;

/// <summary>
/// Reads command envelopes from the shared Service Bus queue and persists the
/// corresponding User / Account / Transaction rows via EF Core.
/// </summary>
public class CommandQueueTrigger
{
    private readonly AppDbContext _db;
    private readonly ILogger<CommandQueueTrigger> _logger;

    public CommandQueueTrigger(AppDbContext db, ILogger<CommandQueueTrigger> logger)
    {
        _db = db;
        _logger = logger;
    }

    [Function("ProcessCommand")]
    public async Task Run(
        [ServiceBusTrigger("%ServiceBusCommandsQueueName%", Connection = "ServiceBusConnection")]
        string messageBody,
        CancellationToken cancellationToken)
    {
        var envelope = CommandEnvelope.Deserialize(messageBody);
        _logger.LogInformation("Processing {CommandType} command", envelope.Type);

        switch (envelope.Type)
        {
            case CommandType.User:
                await HandleUserAsync(envelope.Unwrap<CreateUserCommand>(), cancellationToken);
                break;
            case CommandType.Account:
                await HandleAccountAsync(envelope.Unwrap<CreateAccountCommand>(), cancellationToken);
                break;
            case CommandType.Transaction:
                await HandleTransactionAsync(envelope.Unwrap<CreateTransactionCommand>(), cancellationToken);
                break;
            default:
                throw new InvalidOperationException($"Unknown command type '{envelope.Type}'.");
        }
    }

    private async Task HandleUserAsync(CreateUserCommand command, CancellationToken ct)
    {
        if (await _db.Users.FindAsync([command.Id], ct) is not null)
        {
            _logger.LogInformation("User {UserId} already exists; skipping.", command.Id);
            return;
        }

        _db.Users.Add(new User
        {
            Id = command.Id,
            FirstName = command.FirstName,
            LastName = command.LastName
        });

        await _db.SaveChangesAsync(ct);
        _logger.LogInformation("Created user {UserId}", command.Id);
    }

    private async Task HandleAccountAsync(CreateAccountCommand command, CancellationToken ct)
    {
        if (await _db.Accounts.FindAsync([command.Id], ct) is not null)
        {
            _logger.LogInformation("Account {AccountId} already exists; skipping.", command.Id);
            return;
        }

        _db.Accounts.Add(new Account
        {
            Id = command.Id,
            UserId = command.UserId,
            Name = command.Name
        });

        await _db.SaveChangesAsync(ct);
        _logger.LogInformation("Created account {AccountId} for user {UserId}", command.Id, command.UserId);
    }

    private async Task HandleTransactionAsync(CreateTransactionCommand command, CancellationToken ct)
    {
        if (await _db.Transactions.FindAsync([command.Id], ct) is not null)
        {
            _logger.LogInformation("Transaction {TransactionId} already exists; skipping.", command.Id);
            return;
        }

        _db.Transactions.Add(new Transaction
        {
            Id = command.Id,
            AccountId = command.AccountId,
            Amount = command.Amount
        });

        await _db.SaveChangesAsync(ct);
        _logger.LogInformation("Created transaction {TransactionId} for account {AccountId}", command.Id, command.AccountId);
    }
}
