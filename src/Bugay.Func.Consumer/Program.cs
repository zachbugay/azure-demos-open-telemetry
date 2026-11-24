using Azure.Identity;
using Azure.Monitor.OpenTelemetry.Exporter;
using Bugay.Data;
using Microsoft.Azure.Functions.Worker.Builder;
using Microsoft.Azure.Functions.Worker.OpenTelemetry;
using Microsoft.EntityFrameworkCore;
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
        tracing.AddSqlClientInstrumentation();
    });

builder.Services.AddHttpClient();

var sqlConnectionString =
    configuration["SqlConnectionString"]
    ?? throw new InvalidOperationException("SqlConnectionString is not configured.");

builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlServer(sqlConnectionString));

var app = builder.Build();

app.Run();
