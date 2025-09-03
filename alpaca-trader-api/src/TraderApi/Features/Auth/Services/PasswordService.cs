using BCrypt.Net;

namespace TraderApi.Features.Auth.Services;

public interface IPasswordService
{
    string HashPassword(string password);
    bool VerifyPassword(string password, string hash);
    bool IsPasswordStrong(string password, out string[] errors);
}

public class PasswordService : IPasswordService
{
    private const int WorkFactor = 12;
    
    public string HashPassword(string password)
    {
        return BCrypt.Net.BCrypt.HashPassword(password, WorkFactor);
    }
    
    public bool VerifyPassword(string password, string hash)
    {
        try
        {
            return BCrypt.Net.BCrypt.Verify(password, hash);
        }
        catch
        {
            return false;
        }
    }
    
    public bool IsPasswordStrong(string password, out string[] errors)
    {
        var errorList = new List<string>();
        
        if (string.IsNullOrWhiteSpace(password))
        {
            errorList.Add("Password is required");
            errors = errorList.ToArray();
            return false;
        }
        
        if (password.Length < 8)
        {
            errorList.Add("Password must be at least 8 characters long");
        }
        
        if (!password.Any(char.IsUpper))
        {
            errorList.Add("Password must contain at least one uppercase letter");
        }
        
        if (!password.Any(char.IsLower))
        {
            errorList.Add("Password must contain at least one lowercase letter");
        }
        
        if (!password.Any(char.IsDigit))
        {
            errorList.Add("Password must contain at least one number");
        }
        
        if (!password.Any(ch => !char.IsLetterOrDigit(ch)))
        {
            errorList.Add("Password must contain at least one special character");
        }
        
        errors = errorList.ToArray();
        return errorList.Count == 0;
    }
}