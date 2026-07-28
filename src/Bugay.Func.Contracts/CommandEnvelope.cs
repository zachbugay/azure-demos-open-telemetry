using System;
using System.Text.Json;

namespace Bugay.Func.Contracts;

/// <summary>
/// Envelope that wraps a single create command for transport over the shared
/// Service Bus queue. <see cref="Type"/> tells the Processor which command the
/// JSON <see cref="Payload"/> represents.
/// </summary>
public sealed record CommandEnvelope(CommandType Type, string Payload)
{
    private static readonly JsonSerializerOptions SerializerOptions = new(JsonSerializerDefaults.Web);

    public static CommandEnvelope Wrap(CreateUserCommand command) =>
        new(CommandType.User, JsonSerializer.Serialize(command, SerializerOptions));

    public static CommandEnvelope Wrap(CreateAccountCommand command) =>
        new(CommandType.Account, JsonSerializer.Serialize(command, SerializerOptions));

    public static CommandEnvelope Wrap(CreateTransactionCommand command) =>
        new(CommandType.Transaction, JsonSerializer.Serialize(command, SerializerOptions));

    public T Unwrap<T>() =>
        JsonSerializer.Deserialize<T>(Payload, SerializerOptions)
        ?? throw new InvalidOperationException($"Envelope payload could not be deserialized to {typeof(T).Name}.");

    public string Serialize() => JsonSerializer.Serialize(this, SerializerOptions);

    public static CommandEnvelope Deserialize(string json) =>
        JsonSerializer.Deserialize<CommandEnvelope>(json, SerializerOptions)
        ?? throw new InvalidOperationException("Message body could not be deserialized to a CommandEnvelope.");
}
