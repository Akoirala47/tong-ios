-- Create the user_lesson_progress table
CREATE TABLE IF NOT EXISTS public.user_lesson_progress (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    lesson_id UUID NOT NULL,
    completed BOOLEAN DEFAULT FALSE,
    completed_at TIMESTAMPTZ,
    progress_percent INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, lesson_id)
);

-- Add appropriate indices
CREATE INDEX IF NOT EXISTS idx_user_lesson_progress_user_id ON public.user_lesson_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_user_lesson_progress_lesson_id ON public.user_lesson_progress(lesson_id);
CREATE INDEX IF NOT EXISTS idx_user_lesson_progress_completed ON public.user_lesson_progress(completed);

-- Add RLS policies
ALTER TABLE public.user_lesson_progress ENABLE ROW LEVEL SECURITY;

-- Allow users to see their own progress
CREATE POLICY "Users can view their own lesson progress"
    ON public.user_lesson_progress
    FOR SELECT
    USING (auth.uid() = user_id);

-- Allow users to update their own progress
CREATE POLICY "Users can update their own lesson progress"
    ON public.user_lesson_progress
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Allow users to update their own progress
CREATE POLICY "Users can update their own lesson progress"
    ON public.user_lesson_progress
    FOR UPDATE
    USING (auth.uid() = user_id);

-- Allow all authenticated users to view data (for the app to function)
-- You may want to refine this in production
CREATE POLICY "Anon can view all lesson progress"
    ON public.user_lesson_progress
    FOR SELECT
    TO anon
    USING (true);

-- Allow anon to insert (for the app to function without auth)
-- You may want to refine this in production
CREATE POLICY "Anon can insert lesson progress"
    ON public.user_lesson_progress
    FOR INSERT
    TO anon
    WITH CHECK (true);

-- Allow anon to update (for the app to function without auth)
-- You may want to refine this in production
CREATE POLICY "Anon can update lesson progress"
    ON public.user_lesson_progress
    FOR UPDATE
    TO anon
    USING (true); 