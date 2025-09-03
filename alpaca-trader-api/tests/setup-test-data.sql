-- Setup test data for Alpaca Trader API

-- Insert test user if not exists
INSERT INTO "Users" ("Id", "AuthSub", "Email", "CreatedAt")
VALUES ('11111111-1111-1111-1111-111111111111', 'test-user-123', 'test@example.com', NOW())
ON CONFLICT ("AuthSub") DO NOTHING;

-- Get the user ID (in case it already existed)
DO $$
DECLARE
    user_id UUID;
BEGIN
    SELECT "Id" INTO user_id FROM "Users" WHERE "AuthSub" = 'test-user-123';
    
    -- Insert Alpaca link for the user
    INSERT INTO "AlpacaLinks" (
        "Id", 
        "UserId", 
        "Env", 
        "AccountId", 
        "ApiKeyId", 
        "ApiSecret",
        "IsBrokerApi",
        "BrokerAccountId",
        "CreatedAt"
    )
    VALUES (
        gen_random_uuid(),
        user_id,
        'paper',
        '920964623',
        -- These are encrypted dummy values (not real keys)
        'encrypted_key_id_placeholder',
        'encrypted_secret_placeholder',
        true,
        '920964623',
        NOW()
    )
    ON CONFLICT ("UserId", "Env") DO UPDATE
    SET "IsBrokerApi" = true,
        "BrokerAccountId" = '920964623';
END $$;