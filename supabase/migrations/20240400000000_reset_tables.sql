-- This migration resets incompatible tables to ensure consistent column types
-- It needs to run before any other migrations

-- Find and drop all dependencies on lessons table
DO $$
DECLARE
    r RECORD;
BEGIN
    -- Find all foreign key constraints referencing lessons table
    FOR r IN SELECT tc.constraint_name, tc.table_name
             FROM information_schema.table_constraints tc
             JOIN information_schema.constraint_column_usage ccu 
             ON tc.constraint_name = ccu.constraint_name
             WHERE tc.constraint_type = 'FOREIGN KEY' 
             AND ccu.table_name = 'lessons'
    LOOP
        -- Drop each constraint
        EXECUTE 'ALTER TABLE ' || quote_ident(r.table_name) || 
                ' DROP CONSTRAINT IF EXISTS ' || quote_ident(r.constraint_name) || ' CASCADE';
    END LOOP;
    
    -- Now try to drop the tables
    EXECUTE 'DROP TABLE IF EXISTS user_flashcard_progress CASCADE';
    EXECUTE 'DROP TABLE IF EXISTS flashcards CASCADE';
    EXECUTE 'DROP TABLE IF EXISTS lessons CASCADE';
    EXECUTE 'DROP TABLE IF EXISTS topics CASCADE';
END
$$;

-- We won't recreate them here - we'll let the subsequent migrations do that
-- with the correct column types 