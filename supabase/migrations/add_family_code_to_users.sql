-- Add family_code column to user_profiles table
-- This is a permanent unique code that never expires

-- First, create a function to generate unique 8-character family codes
CREATE OR REPLACE FUNCTION generate_family_code()
RETURNS TEXT AS $$
DECLARE
  chars TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; -- Exclude confusing characters: I, O, 0, 1
  result TEXT := '';
  i INTEGER;
  code_exists BOOLEAN;
BEGIN
  LOOP
    result := '';
    -- Generate 8-character code
    FOR i IN 1..8 LOOP
      result := result || substr(chars, floor(random() * length(chars) + 1)::int, 1);
    END LOOP;

    -- Check if code already exists
    SELECT EXISTS(SELECT 1 FROM user_profiles WHERE family_code = result) INTO code_exists;

    -- If code doesn't exist, we can use it
    IF NOT code_exists THEN
      EXIT;
    END IF;
  END LOOP;

  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Add family_code column if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'user_profiles' AND column_name = 'family_code'
  ) THEN
    ALTER TABLE user_profiles ADD COLUMN family_code TEXT;
  END IF;
END $$;

-- Create unique index on family_code
CREATE UNIQUE INDEX IF NOT EXISTS idx_user_profiles_family_code ON user_profiles(family_code);

-- Update existing users to have family codes
UPDATE user_profiles
SET family_code = generate_family_code()
WHERE family_code IS NULL OR family_code = '';

-- Add NOT NULL constraint after populating existing records
ALTER TABLE user_profiles ALTER COLUMN family_code SET NOT NULL;

-- Create a trigger to automatically generate family_code for new users
CREATE OR REPLACE FUNCTION set_family_code_on_insert()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.family_code IS NULL OR NEW.family_code = '' THEN
    NEW.family_code := generate_family_code();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_set_family_code ON user_profiles;
CREATE TRIGGER trigger_set_family_code
  BEFORE INSERT ON user_profiles
  FOR EACH ROW
  EXECUTE FUNCTION set_family_code_on_insert();

-- Add comment
COMMENT ON COLUMN user_profiles.family_code IS 'Unique permanent 8-character code for family connections. Never expires.';
