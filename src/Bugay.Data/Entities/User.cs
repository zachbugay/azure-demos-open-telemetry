using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace Bugay.Data.Entities;

public partial class User
{
    [Key]
    public Guid Id { get; set; }

    [StringLength(100)]
    public string FirstName { get; set; } = null!;

    [StringLength(100)]
    public string LastName { get; set; } = null!;

    [Precision(3)]
    public DateTime CreatedAtUtc { get; set; }

    [InverseProperty("User")]
    public virtual ICollection<Account> Accounts { get; set; } = new List<Account>();
}
