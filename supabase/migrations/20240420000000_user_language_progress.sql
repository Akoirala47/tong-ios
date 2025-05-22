-- Create schema for tracking user language levels
CREATE TABLE IF NOT EXISTS user_language_levels (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    lang_code TEXT NOT NULL,
    level_code TEXT NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, lang_code)
);

-- Make sure the lessons table exists before creating flashcards
CREATE TABLE IF NOT EXISTS lessons (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    content TEXT,
    topic_id UUID,
    order_in_topic INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create a table for flashcards
CREATE TABLE IF NOT EXISTS flashcards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    word TEXT NOT NULL,
    translation TEXT NOT NULL,
    ipa TEXT,
    audio_url TEXT,
    image_url TEXT,
    example_sentence TEXT NOT NULL,
    grammar_explanation TEXT,
    order_in_lesson INTEGER NOT NULL,
    lesson_id UUID REFERENCES lessons(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create schema for tracking flashcard progress and spaced repetition
CREATE TABLE IF NOT EXISTS user_flashcard_progress (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    flashcard_id UUID NOT NULL REFERENCES flashcards(id) ON DELETE CASCADE,
    lang_code TEXT NOT NULL,
    interval INTEGER DEFAULT 0,
    due_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_review_date TIMESTAMP WITH TIME ZONE,
    review_count INTEGER DEFAULT 0,
    last_difficulty INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, flashcard_id)
);

-- Create schema for tracking quiz and boss battle results
CREATE TABLE IF NOT EXISTS user_quiz_results (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    lang_code TEXT NOT NULL,
    level_code TEXT NOT NULL,
    quiz_type TEXT NOT NULL, -- 'placement', 'boss_battle', etc.
    score INTEGER NOT NULL,
    max_score INTEGER NOT NULL,
    questions_total INTEGER NOT NULL,
    questions_correct INTEGER NOT NULL,
    time_taken INTEGER, -- seconds
    completed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS user_language_levels_user_id_idx ON user_language_levels(user_id);
CREATE INDEX IF NOT EXISTS user_language_levels_lang_code_idx ON user_language_levels(lang_code);
CREATE INDEX IF NOT EXISTS user_flashcard_progress_user_id_idx ON user_flashcard_progress(user_id);
CREATE INDEX IF NOT EXISTS user_flashcard_progress_due_date_idx ON user_flashcard_progress(due_date);
CREATE INDEX IF NOT EXISTS user_flashcard_progress_lang_code_idx ON user_flashcard_progress(lang_code);
CREATE INDEX IF NOT EXISTS user_quiz_results_user_id_idx ON user_quiz_results(user_id);
CREATE INDEX IF NOT EXISTS user_quiz_results_lang_code_idx ON user_quiz_results(lang_code);

-- Create RLS policies for the tables

-- User language levels
ALTER TABLE user_language_levels ENABLE ROW LEVEL SECURITY;

CREATE POLICY select_own_language_levels ON user_language_levels
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY insert_own_language_levels ON user_language_levels
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY update_own_language_levels ON user_language_levels
    FOR UPDATE
    USING (auth.uid() = user_id);

-- User flashcard progress
ALTER TABLE user_flashcard_progress ENABLE ROW LEVEL SECURITY;

CREATE POLICY select_own_flashcard_progress ON user_flashcard_progress
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY insert_own_flashcard_progress ON user_flashcard_progress
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY update_own_flashcard_progress ON user_flashcard_progress
    FOR UPDATE
    USING (auth.uid() = user_id);

-- User quiz results
ALTER TABLE user_quiz_results ENABLE ROW LEVEL SECURITY;

CREATE POLICY select_own_quiz_results ON user_quiz_results
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY insert_own_quiz_results ON user_quiz_results
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Create function for getting due flashcards (for backend operations)
CREATE OR REPLACE FUNCTION get_due_flashcards(
    p_user_id UUID,
    p_lang_code TEXT,
    p_limit INTEGER DEFAULT 20
)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    flashcard_id UUID,
    lang_code TEXT,
    interval INTEGER,
    due_date TIMESTAMP WITH TIME ZONE,
    last_review_date TIMESTAMP WITH TIME ZONE,
    review_count INTEGER,
    last_difficulty INTEGER,
    word TEXT,
    translation TEXT,
    example_sentence TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ufp.id,
        ufp.user_id,
        ufp.flashcard_id,
        ufp.lang_code,
        ufp.interval,
        ufp.due_date,
        ufp.last_review_date,
        ufp.review_count,
        ufp.last_difficulty,
        f.word,
        f.translation,
        f.example_sentence
    FROM 
        user_flashcard_progress ufp
    JOIN 
        flashcards f ON ufp.flashcard_id = f.id
    WHERE 
        ufp.user_id = p_user_id
        AND ufp.lang_code = p_lang_code
        AND ufp.due_date <= NOW()
    ORDER BY 
        ufp.due_date ASC
    LIMIT 
        p_limit;
END;
$$ LANGUAGE plpgsql; 