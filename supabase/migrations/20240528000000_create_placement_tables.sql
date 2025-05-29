-- Create user_placement_tests table to track placement test results
CREATE TABLE IF NOT EXISTS public.user_placement_tests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    lang_code TEXT NOT NULL,
    level_code TEXT NOT NULL,
    completed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    has_taken_test BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, lang_code)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_user_placement_tests_user_id ON public.user_placement_tests(user_id);
CREATE INDEX IF NOT EXISTS idx_user_placement_tests_lang_code ON public.user_placement_tests(lang_code);

-- Enable Row Level Security
ALTER TABLE public.user_placement_tests ENABLE ROW LEVEL SECURITY;

-- Create policies for user_placement_tests
CREATE POLICY "Users can view their own placement tests" ON public.user_placement_tests
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own placement tests" ON public.user_placement_tests
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own placement tests" ON public.user_placement_tests
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Make sure the user_language_levels table exists
CREATE TABLE IF NOT EXISTS public.user_language_levels (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    lang_code TEXT NOT NULL,
    level_code TEXT NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, lang_code)
);

-- Create indexes for user_language_levels if they don't exist
CREATE INDEX IF NOT EXISTS idx_user_language_levels_user_id ON public.user_language_levels(user_id);
CREATE INDEX IF NOT EXISTS idx_user_language_levels_lang_code ON public.user_language_levels(lang_code);

-- Enable Row Level Security for user_language_levels
ALTER TABLE public.user_language_levels ENABLE ROW LEVEL SECURITY;

-- Create policies for user_language_levels if they don't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT FROM pg_policies 
        WHERE tablename = 'user_language_levels' AND policyname = 'Users can view their own language levels'
    ) THEN
        CREATE POLICY "Users can view their own language levels" ON public.user_language_levels
            FOR SELECT USING (auth.uid() = user_id);
    END IF;
    
    IF NOT EXISTS (
        SELECT FROM pg_policies 
        WHERE tablename = 'user_language_levels' AND policyname = 'Users can update their own language levels'
    ) THEN
        CREATE POLICY "Users can update their own language levels" ON public.user_language_levels
            FOR UPDATE USING (auth.uid() = user_id);
    END IF;
    
    IF NOT EXISTS (
        SELECT FROM pg_policies 
        WHERE tablename = 'user_language_levels' AND policyname = 'Users can insert their own language levels'
    ) THEN
        CREATE POLICY "Users can insert their own language levels" ON public.user_language_levels
            FOR INSERT WITH CHECK (auth.uid() = user_id);
    END IF;
END
$$;
