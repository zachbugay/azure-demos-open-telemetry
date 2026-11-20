using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace Bugay.Data.Entities;

[Index("AccountId", Name = "IX_Transactions_AccountId")]
public partial class Transaction
{
    [Key]
    public Guid Id { get; set; }

    public Guid AccountId { get; set; }

    [Column(TypeName = "decimal(19, 4)")]
    public decimal Amount { get; set; }

    [Precision(3)]
    public DateTime CreatedAtUtc { get; set; }

    [ForeignKey("AccountId")]
    [InverseProperty("Transactions")]
    public virtual Account Account { get; set; } = null!;
}
