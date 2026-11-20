using Azure.Identity;
using Azure.Messaging.ServiceBus;
using Azure.Monitor.OpenTelemetry.Exporter;
using Microsoft.Azure.Functions.Worker.Builder;
using Microsoft.Azure.Functions.Worker.OpenTelemetry;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using OpenTelemetry;
using OpenTelemetry.Trace;
using System;

var builder = FunctionsApplication.CreateBuilder(args);

builder.ConfigureFunctionsWebApplication();

var configuration = builder.Configuration;
var clientId = configuration["AZURE_CLIENT_ID"];

builder.Logging.AddOpenTelemetry(logging =>
{
    logging.IncludeFormattedMessage = true;
    logging.IncludeScopes = true;
});

builder.Services.AddOpenTelemetry()
    .UseFunctionsWorkerDefaults()
    .UseAzureMonitorExporter(options =>
    {
        var credentialOptions = new DefaultAzureCredentialOptions
        {
            ManagedIdentityClientId = clientId
        };

        var credential = new DefaultAzureCredential(credentialOptions);

        options.Credential = new DefaultAzureCredential(credentialOptions);
    })
    .WithTracing(tracing =>
    {
        tracing.AddHttpClientInstrumentation();
        tracing.AddSource("Azure.Messaging.ServiceBus");
    });

builder.Services.AddHttpClient();

var serviceBusNamespace =
    configuration["ServiceBusConnection:fullyQualifiedNamespace"]
    ?? throw new InvalidOperationException(
        "ServiceBusConnection__fullyQualifiedNamespace is not configured.");

var queueName = configuration["ServiceBusCommandsQueueName"] ?? "sbq-commands";

builder.Services.AddSingleton(_ =>
{
    var credential = new DefaultAzureCredential(new DefaultAzureCredentialOptions
    {
        ManagedIdentityClientId = clientId
    });

    return new ServiceBusClient(serviceBusNamespace, credential);
});

builder.Services.AddSingleton(sp =>
    sp.GetRequiredService<ServiceBusClient>().CreateSender(queueName));

var app = builder.Build();

app.Run();
