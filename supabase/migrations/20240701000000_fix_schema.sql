-- Drop existing related tables if they exist
DROP TABLE IF EXISTS user_flashcard_progress;
DROP TABLE IF EXISTS flashcards;
DROP TABLE IF EXISTS lessons;

-- Recreate lessons table with UUID primary key
CREATE TABLE IF NOT EXISTS lessons (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    content TEXT,
    topic_id UUID,
    order_in_topic INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create flashcards table with proper foreign key
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

-- Recreate user flashcard progress table
CREATE TABLE IF NOT EXISTS user_flashcard_progress (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id TEXT NOT NULL,
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

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS user_flashcard_progress_user_id_idx ON user_flashcard_progress(user_id);
CREATE INDEX IF NOT EXISTS user_flashcard_progress_due_date_idx ON user_flashcard_progress(due_date);
CREATE INDEX IF NOT EXISTS user_flashcard_progress_lang_code_idx ON user_flashcard_progress(lang_code);

-- Enable row level security and add policies
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