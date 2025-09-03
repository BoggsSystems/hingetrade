using System.Security.Cryptography;
using System.Text;

namespace TraderApi.Security;

public interface IKeyProtector
{
    string Encrypt(string plainText);
    string Decrypt(string cipherText);
}

public class KeyProtector : IKeyProtector
{
    private readonly byte[] _key;

    public KeyProtector(string key)
    {
        _key = DeriveKey(key);
    }

    private static byte[] DeriveKey(string password)
    {
        using var sha256 = SHA256.Create();
        return sha256.ComputeHash(Encoding.UTF8.GetBytes(password));
    }

    public string Encrypt(string plainText)
    {
        using var aesGcm = new AesGcm(_key, AesGcm.TagByteSizes.MaxSize);
        var nonce = new byte[AesGcm.NonceByteSizes.MaxSize];
        RandomNumberGenerator.Fill(nonce);

        var plainBytes = Encoding.UTF8.GetBytes(plainText);
        var cipherBytes = new byte[plainBytes.Length];
        var tag = new byte[AesGcm.TagByteSizes.MaxSize];

        aesGcm.Encrypt(nonce, plainBytes, cipherBytes, tag);

        var result = new byte[nonce.Length + tag.Length + cipherBytes.Length];
        Buffer.BlockCopy(nonce, 0, result, 0, nonce.Length);
        Buffer.BlockCopy(tag, 0, result, nonce.Length, tag.Length);
        Buffer.BlockCopy(cipherBytes, 0, result, nonce.Length + tag.Length, cipherBytes.Length);

        return Convert.ToBase64String(result);
    }

    public string Decrypt(string cipherText)
    {
        try 
        {
            var data = Convert.FromBase64String(cipherText);

            var nonce = new byte[AesGcm.NonceByteSizes.MaxSize];
            var tag = new byte[AesGcm.TagByteSizes.MaxSize];
            var cipherBytes = new byte[data.Length - nonce.Length - tag.Length];

            Buffer.BlockCopy(data, 0, nonce, 0, nonce.Length);
            Buffer.BlockCopy(data, nonce.Length, tag, 0, tag.Length);
            Buffer.BlockCopy(data, nonce.Length + tag.Length, cipherBytes, 0, cipherBytes.Length);

            using var aesGcm = new AesGcm(_key, AesGcm.TagByteSizes.MaxSize);
            var plainBytes = new byte[cipherBytes.Length];
            aesGcm.Decrypt(nonce, cipherBytes, tag, plainBytes);

            return Encoding.UTF8.GetString(plainBytes);
        }
        catch (FormatException)
        {
            // If it's not a valid base64 string, assume it's already decrypted (for development)
            return cipherText;
        }
    }
}