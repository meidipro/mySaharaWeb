-- FIXED VERSION: Add family_code column to users table
-- This version checks for different possible table names

-- First, create a function to generate unique 8-character family codes
CREATE OR REPLACE FUNCTION generate_family_code()
RETURNS TEXT AS $$
DECLARE
  chars TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; -- Exclude confusing characters: I, O, 0, 1
  result TEXT := '';
  i INTEGER;
  code_exists BOOLEAN;
  target_table TEXT;
BEGIN
  -- Find the correct table name (try common variations)
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_profiles') THEN
    target_table := 'user_profiles';
  ELSIF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users') THEN
    target_table := 'users';
  ELSIF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'profiles') THEN
    target_table := 'profiles';
  ELSE
    RAISE EXCEPTION 'Could not find user table. Please check table name.';
  END IF;

  LOOP
    result := '';
    -- Generate 8-character code
    FOR i IN 1..8 LOOP
      result := result || substr(chars, floor(random() * length(chars) + 1)::int, 1);
    END LOOP;

    -- Check if code already exists using dynamic SQL
    EXECUTE format('SELECT EXISTS(SELECT 1 FROM %I WHERE family_code = $1)', target_table)
    INTO code_exists
    USING result;

    -- If code doesn't exist, we can use it
    IF NOT code_exists THEN
      EXIT;
    END IF;
  END LOOP;

  RETURN result;
END;
$$ LANGUAGE plpgsql;


-- Now add family_code column to the correct table
-- This script tries different table names automatically

DO $$
DECLARE
  target_table TEXT;
  table_exists BOOLEAN;
BEGIN
  -- Try to find the user table (try common variations)
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_profiles' AND table_schema = 'public') THEN
    target_table := 'user_profiles';
  ELSIF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users' AND table_schema = 'public') THEN
    target_table := 'users';
  ELSIF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'profiles' AND table_schema = 'public') THEN
    target_table := 'profiles';
  ELSE
    RAISE EXCEPTION 'Could not find user table. Available tables: %',
      (SELECT string_agg(table_name, ', ')
       FROM information_schema.tables
       WHERE table_schema = 'public');
  END IF;

  RAISE NOTICE 'Found user table: %', target_table;

  -- Check if family_code column already exists
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = target_table
      AND column_name = 'family_code'
      AND table_schema = 'public'
  ) THEN
    -- Add the column
    EXECUTE format('ALTER TABLE %I ADD COLUMN family_code TEXT', target_table);
    RAISE NOTICE 'Added family_code column to %', target_table;

    -- Create unique index
    EXECUTE format('CREATE UNIQUE INDEX IF NOT EXISTS idx_%I_family_code ON %I(family_code)', target_table, target_table);
    RAISE NOTICE 'Created unique index on family_code';

    -- Update existing users to have family codes
    EXECUTE format('UPDATE %I SET family_code = generate_family_code() WHERE family_code IS NULL OR family_code = ''''', target_table);
    RAISE NOTICE 'Generated family codes for existing users';

    -- Add NOT NULL constraint
    EXECUTE format('ALTER TABLE %I ALTER COLUMN family_code SET NOT NULL', target_table);
    RAISE NOTICE 'Set family_code as NOT NULL';

  ELSE
    RAISE NOTICE 'family_code column already exists in %', target_table;
  END IF;

  -- Create trigger for new users
  EXECUTE format('
    CREATE OR REPLACE FUNCTION set_family_code_on_insert_%I()
    RETURNS TRIGGER AS $trigger$
    BEGIN
      IF NEW.family_code IS NULL OR NEW.family_code = '''' THEN
        NEW.family_code := generate_family_code();
      END IF;
      RETURN NEW;
    END;
    $trigger$ LANGUAGE plpgsql;
  ', target_table);

  EXECUTE format('DROP TRIGGER IF EXISTS trigger_set_family_code ON %I', target_table);
  EXECUTE format('
    CREATE TRIGGER trigger_set_family_code
      BEFORE INSERT ON %I
      FOR EACH ROW
      EXECUTE FUNCTION set_family_code_on_insert_%I();
  ', target_table, target_table);

  RAISE NOTICE 'Created trigger for automatic family code generation';

  -- Add comment
  EXECUTE format('COMMENT ON COLUMN %I.family_code IS ''Unique permanent 8-character code for family connections. Never expires.''', target_table);

  RAISE NOTICE 'Migration completed successfully!';
  RAISE NOTICE 'Target table was: %', target_table;

EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Error: %', SQLERRM;
  RAISE;
END $$;


-- Verify the migration
DO $$
DECLARE
  target_table TEXT;
  code_count INTEGER;
BEGIN
  -- Find the table again
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_profiles' AND table_schema = 'public') THEN
    target_table := 'user_profiles';
  ELSIF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users' AND table_schema = 'public') THEN
    target_table := 'users';
  ELSIF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'profiles' AND table_schema = 'public') THEN
    target_table := 'profiles';
  ELSE
    RETURN;
  END IF;

  -- Count users with family codes
  EXECUTE format('SELECT COUNT(*) FROM %I WHERE family_code IS NOT NULL', target_table)
  INTO code_count;

  RAISE NOTICE '========================================';
  RAISE NOTICE 'VERIFICATION:';
  RAISE NOTICE 'Table: %', target_table;
  RAISE NOTICE 'Users with family codes: %', code_count;
  RAISE NOTICE '========================================';
END $$;


-- Show a sample of family codes
DO $$
DECLARE
  target_table TEXT;
BEGIN
  -- Find the table
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_profiles' AND table_schema = 'public') THEN
    target_table := 'user_profiles';
  ELSIF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users' AND table_schema = 'public') THEN
    target_table := 'users';
  ELSIF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'profiles' AND table_schema = 'public') THEN
    target_table := 'profiles';
  ELSE
    RETURN;
  END IF;

  RAISE NOTICE 'Sample family codes:';
  RAISE NOTICE 'Run this query to see codes: SELECT id, email, family_code FROM % LIMIT 5;', target_table;
END $$;
