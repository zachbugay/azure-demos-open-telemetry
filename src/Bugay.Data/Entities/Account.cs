using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace Bugay.Data.Entities;

[Index("UserId", Name = "IX_Accounts_UserId")]
public partial class Account
{
    [Key]
    public Guid Id { get; set; }

    public Guid UserId { get; set; }

    [StringLength(200)]
    public string? Name { get; set; }

    [Precision(3)]
    public DateTime CreatedAtUtc { get; set; }

    [InverseProperty("Account")]
    public virtual ICollection<Transaction> Transactions { get; set; } = new List<Transaction>();

    [ForeignKey("UserId")]
    [InverseProperty("Accounts")]
    public virtual User User { get; set; } = null!;
}
