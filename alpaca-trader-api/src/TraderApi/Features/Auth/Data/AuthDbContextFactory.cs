using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace TraderApi.Features.Auth.Data;

public class AuthDbContextFactory : IDesignTimeDbContextFactory<AuthDbContext>
{
    public AuthDbContext CreateDbContext(string[] args)
    {
        var optionsBuilder = new DbContextOptionsBuilder<AuthDbContext>();
        
        // Use the same connection string as in appsettings.json
        optionsBuilder.UseNpgsql("Host=localhost;Port=5432;Database=trader;Username=postgres;Password=postgres");
        
        return new AuthDbContext(optionsBuilder.Options);
    }
}