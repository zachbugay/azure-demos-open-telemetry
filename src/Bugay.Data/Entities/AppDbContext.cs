using System;
using System.Collections.Generic;
using Bugay.Data.Entities;
using Microsoft.EntityFrameworkCore;

namespace Bugay.Data;

public partial class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options)
        : base(options)
    {
    }

    public virtual DbSet<Account> Accounts { get; set; }

    public virtual DbSet<SchemaVersion> SchemaVersions { get; set; }

    public virtual DbSet<Transaction> Transactions { get; set; }

    public virtual DbSet<User> Users { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Account>(entity =>
        {
            entity.Property(e => e.Id).ValueGeneratedNever();
            entity.Property(e => e.CreatedAtUtc).HasDefaultValueSql("(sysutcdatetime())", "DF_Accounts_CreatedAtUtc");

            entity.HasOne(d => d.User).WithMany(p => p.Accounts).OnDelete(DeleteBehavior.ClientSetNull);
        });

        modelBuilder.Entity<SchemaVersion>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK_SchemaVersions_Id");
        });

        modelBuilder.Entity<Transaction>(entity =>
        {
            entity.Property(e => e.Id).ValueGeneratedNever();
            entity.Property(e => e.CreatedAtUtc).HasDefaultValueSql("(sysutcdatetime())", "DF_Transactions_CreatedAtUtc");

            entity.HasOne(d => d.Account).WithMany(p => p.Transactions).OnDelete(DeleteBehavior.ClientSetNull);
        });

        modelBuilder.Entity<User>(entity =>
        {
            entity.Property(e => e.Id).ValueGeneratedNever();
            entity.Property(e => e.CreatedAtUtc).HasDefaultValueSql("(sysutcdatetime())", "DF_Users_CreatedAtUtc");
        });

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
