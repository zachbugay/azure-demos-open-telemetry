using System;
using System.Reflection;
using System.Threading;
using System.Threading.Tasks;
using Azure.Core;
using DbUp;
using DbUp.Engine;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace Bugay.Database;

public sealed class Runner : BackgroundService
{
    private readonly ILogger<Runner> _logger;
    private readonly TokenCredential _credential;
    private readonly string _connectionString;
    private readonly IHostApplicationLifetime _appLifetime;

    public Runner(
        ILogger<Runner> logger,
        TokenCredential credential,
        DatabaseConnectionOptions options,
        IHostApplicationLifetime appLifetime)
    {
        _logger = logger;
        _credential = credential;
        _connectionString = options.ConnectionString;
        _appLifetime = appLifetime;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        try
        {
            await Execute(stoppingToken);
        }
        finally
        {
            // Stop the host so the application exits once the upgrade has run.
            _appLifetime.StopApplication();
        }
    }

    public Task Execute(CancellationToken cancellationToken = default)
    {
        UpgradeEngine upgrader =
            DeployChanges.To
                .AzureSqlDatabaseWithIntegratedSecurity(_connectionString, tokenCredential: _credential)
                .WithScriptsEmbeddedInAssembly(Assembly.GetExecutingAssembly())
                .WithTransactionPerScript()
                .LogToConsole()
                .Build();

        DatabaseUpgradeResult result = upgrader.PerformUpgrade();

        if (!result.Successful)
        {
            _logger.LogError(result.Error, "Database upgrade failed.");
            Environment.ExitCode = 1;
            return Task.CompletedTask;
        }

        _logger.LogInformation("Database upgrade successful.");
        return Task.CompletedTask;
    }
}
