using System;
using Azure.Identity;
using Azure.Monitor.OpenTelemetry.AspNetCore;
using Bugay.Data.Generator;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using OpenTelemetry.Metrics;
using OpenTelemetry.Trace;

var builder = Host.CreateApplicationBuilder(args);
var configuration = builder.Configuration;

var managedIdentityClientId = configuration["AZURE_CLIENT_ID"];
var credential = new DefaultAzureCredential(new DefaultAzureCredentialOptions
{
    ManagedIdentityClientId = managedIdentityClientId
});

builder.Services.AddOpenTelemetry()
    .UseAzureMonitor(options => options.Credential = credential)
    .WithTracing(tracing => tracing.AddHttpClientInstrumentation())
    .WithMetrics(metrics =>
    {
        metrics.AddProcessInstrumentation();
        metrics.AddRuntimeInstrumentation();
    });

var subscriptionKey = configuration["ApimSubscriptionKey"];

var baseAddress = configuration["ApimBaseAddress"]
    ?? throw new InvalidOperationException("Configuration value 'ApimBaseAddress' is required.");

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
