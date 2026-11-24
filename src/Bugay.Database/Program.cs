using System;
using Azure.Core;
using Azure.Identity;
using Azure.Monitor.OpenTelemetry.AspNetCore;
using Bugay.Database;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using OpenTelemetry.Metrics;
using OpenTelemetry.Trace;

var builder = Host.CreateApplicationBuilder(args);
var configuration = builder.Configuration;

var credential = new DefaultAzureCredential();
var connectionString = configuration["DATABASE_CONNECTION_STRING"]
    ?? configuration["SqlConnectionString"]
    ?? throw new InvalidOperationException("Connection string is required, but missing!");

builder.Services.AddSingleton<TokenCredential>(credential);
builder.Services.AddSingleton(new DatabaseConnectionOptions(connectionString));

var telemetry = builder.Services.AddOpenTelemetry();

if (!string.IsNullOrWhiteSpace(configuration["APPLICATIONINSIGHTS_CONNECTION_STRING"]))
{
    telemetry.UseAzureMonitor(options => options.Credential = credential);
}

telemetry
    .WithTracing(tracing => tracing.AddHttpClientInstrumentation())
    .WithMetrics(metrics =>
    {
        metrics.AddProcessInstrumentation();
        metrics.AddRuntimeInstrumentation();
    });

builder.Services.AddHostedService<Runner>();

using var host = builder.Build();

await host.RunAsync();

return Environment.ExitCode;
