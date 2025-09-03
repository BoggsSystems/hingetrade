using Microsoft.EntityFrameworkCore;
using TraderApi.Features.Auth.Data;
using TraderApi.Features.Auth.Models;

namespace TraderApi.Features.Auth.Services;

public interface IUserService
{
    Task<User?> GetByIdAsync(Guid id);
    Task<User?> GetByEmailAsync(string email);
    Task<User?> GetByUsernameAsync(string username);
    Task<bool> EmailExistsAsync(string email);
    Task<bool> UsernameExistsAsync(string username);
    Task<User> CreateUserAsync(string email, string username, string passwordHash);
    Task<IEnumerable<string>> GetUserRolesAsync(Guid userId);
    Task AddUserToRoleAsync(Guid userId, string roleName);
    Task UpdateUserAsync(User user);
}

public class UserService : IUserService
{
    private readonly AuthDbContext _context;
    
    public UserService(AuthDbContext context)
    {
        _context = context;
    }
    
    public async Task<User?> GetByIdAsync(Guid id)
    {
        return await _context.Users
            .Include(u => u.UserRoles)
            .ThenInclude(ur => ur.Role)
            .FirstOrDefaultAsync(u => u.Id == id);
    }
    
    public async Task<User?> GetByEmailAsync(string email)
    {
        return await _context.Users
            .Include(u => u.UserRoles)
            .ThenInclude(ur => ur.Role)
            .FirstOrDefaultAsync(u => u.Email.ToLower() == email.ToLower());
    }
    
    public async Task<User?> GetByUsernameAsync(string username)
    {
        return await _context.Users
            .Include(u => u.UserRoles)
            .ThenInclude(ur => ur.Role)
            .FirstOrDefaultAsync(u => u.Username.ToLower() == username.ToLower());
    }
    
    public async Task<bool> EmailExistsAsync(string email)
    {
        return await _context.Users.AnyAsync(u => u.Email.ToLower() == email.ToLower());
    }
    
    public async Task<bool> UsernameExistsAsync(string username)
    {
        return await _context.Users.AnyAsync(u => u.Username != null && u.Username.ToLower() == username.ToLower());
    }
    
    public async Task<User> CreateUserAsync(string email, string username, string passwordHash)
    {
        var user = new User
        {
            Id = Guid.NewGuid(),
            Email = email.ToLower(),
            Username = username,
            PasswordHash = passwordHash,
            EmailVerified = false,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };
        
        _context.Users.Add(user);
        await _context.SaveChangesAsync();
        
        // Add default "User" role
        await AddUserToRoleAsync(user.Id, "User");
        
        return user;
    }
    
    public async Task<IEnumerable<string>> GetUserRolesAsync(Guid userId)
    {
        var user = await _context.Users
            .Include(u => u.UserRoles)
            .ThenInclude(ur => ur.Role)
            .FirstOrDefaultAsync(u => u.Id == userId);
            
        if (user == null) return Enumerable.Empty<string>();
        
        return user.UserRoles.Select(ur => ur.Role.Name);
    }
    
    public async Task AddUserToRoleAsync(Guid userId, string roleName)
    {
        var role = await _context.Roles.FirstOrDefaultAsync(r => r.Name == roleName);
        if (role == null) throw new ArgumentException($"Role '{roleName}' not found");
        
        var exists = await _context.UserRoles.AnyAsync(ur => ur.UserId == userId && ur.RoleId == role.Id);
        if (exists) return;
        
        _context.UserRoles.Add(new UserRole { UserId = userId, RoleId = role.Id });
        await _context.SaveChangesAsync();
    }
    
    public async Task UpdateUserAsync(User user)
    {
        user.UpdatedAt = DateTime.UtcNow;
        _context.Users.Update(user);
        await _context.SaveChangesAsync();
    }
}