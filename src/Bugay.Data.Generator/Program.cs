using Azure.Identity;
using Azure.Monitor.OpenTelemetry.AspNetCore;
using Bugay.Data.Generator;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using OpenTelemetry.Metrics;
using OpenTelemetry.Trace;
using System;

var builder = Host.CreateApplicationBuilder(args);
var configuration = builder.Configuration;

var telemetry = builder.Services.AddOpenTelemetry();

if (!string.IsNullOrWhiteSpace(configuration["APPLICATIONINSIGHTS_CONNECTION_STRING"]))
{
    telemetry.UseAzureMonitor(options =>
    {
        options.Credential = new DefaultAzureCredential(new DefaultAzureCredentialOptions
        {
            ManagedIdentityClientId = configuration["AZURE_CLIENT_ID"]
        });
    });
}

telemetry.WithTracing(tracing => tracing.AddHttpClientInstrumentation())
    .WithMetrics(metrics =>
    {
        metrics.AddProcessInstrumentation();
        metrics.AddRuntimeInstrumentation();
    });

var subscriptionKey = configuration["ApimSubscriptionKey"];

var baseAddress = configuration["ProducerBaseAddress"];
if (string.IsNullOrWhiteSpace(baseAddress))
{
    var apimBaseAddress = configuration["ApimBaseAddress"]
        ?? throw new InvalidOperationException("Configuration value 'ProducerBaseAddress' or 'ApimBaseAddress' is required.");
    baseAddress = new Uri(new Uri(apimBaseAddress), "producer/").AbsoluteUri;
}

builder.Services.AddHttpClient<DataGenerator>(client =>
{
    client.BaseAddress = new Uri(baseAddress);
    if (!string.IsNullOrWhiteSpace(subscriptionKey))
    {
        client.DefaultRequestHeaders.Add("Ocp-Apim-Subscription-Key", subscriptionKey);
    }
});

using var host = builder.Build();
await host.StartAsync();

try
{
    var userCount = configuration.GetValue("GeneratorUserCount", 10);
    if (userCount <= 0)
    {
        userCount = 10;
    }

    var generator = host.Services.GetRequiredService<DataGenerator>();
    await generator.GenerateAsync(userCount, host.Services.GetRequiredService<IHostApplicationLifetime>().ApplicationStopping);
}
finally
{
    // Stopping the host flushes the OpenTelemetry batch exporters before exit.
    await host.StopAsync();
}
