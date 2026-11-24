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

var telemetry = builder.Services.AddOpenTelemetry()
    .UseFunctionsWorkerDefaults();

if (!string.IsNullOrWhiteSpace(configuration["OTEL_EXPORTER_OTLP_ENDPOINT"]))
{
    telemetry.UseOtlpExporter();
}

if (!string.IsNullOrWhiteSpace(configuration["APPLICATIONINSIGHTS_CONNECTION_STRING"]))
{
    telemetry.UseAzureMonitorExporter(options =>
    {
        options.Credential = new DefaultAzureCredential(new DefaultAzureCredentialOptions
        {
            ManagedIdentityClientId = clientId
        });
    });
}

telemetry.WithTracing(tracing =>
    {
        tracing.AddHttpClientInstrumentation();
        tracing.AddSource("Azure.Messaging.ServiceBus");
    });

builder.Services.AddHttpClient();

var serviceBusConnectionString = configuration["ServiceBusConnection"];
var serviceBusNamespace =
    configuration["ServiceBusConnection:fullyQualifiedNamespace"];

if (string.IsNullOrWhiteSpace(serviceBusConnectionString) &&
    string.IsNullOrWhiteSpace(serviceBusNamespace))
{
    throw new InvalidOperationException(
        "ServiceBusConnection or ServiceBusConnection__fullyQualifiedNamespace is not configured.");
}

var queueName = configuration["ServiceBusCommandsQueueName"] ?? "sbq-commands";

builder.Services.AddSingleton(_ =>
{
    if (!string.IsNullOrWhiteSpace(serviceBusConnectionString))
    {
        return new ServiceBusClient(serviceBusConnectionString);
    }

    var credential = new DefaultAzureCredential(new DefaultAzureCredentialOptions
    {
        ManagedIdentityClientId = clientId
    });

    return new ServiceBusClient(serviceBusNamespace!, credential);
});

builder.Services.AddSingleton(sp =>
    sp.GetRequiredService<ServiceBusClient>().CreateSender(queueName));

var app = builder.Build();

app.Run();
