-- Create languages table
CREATE TABLE IF NOT EXISTS public.languages (
  id SERIAL PRIMARY KEY,
  code TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create language_levels table
CREATE TABLE IF NOT EXISTS public.language_levels (
  id SERIAL PRIMARY KEY,
  code TEXT NOT NULL,
  name TEXT NOT NULL,
  ordinal INTEGER NOT NULL,
  language_id INTEGER NOT NULL REFERENCES public.languages(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(code, language_id)
);

-- Create topics table
CREATE TABLE IF NOT EXISTS public.topics (
  id SERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  slug TEXT NOT NULL,
  can_do_statement TEXT,
  language_level_id INTEGER NOT NULL REFERENCES public.language_levels(id) ON DELETE CASCADE,
  order_in_level INTEGER NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(slug, language_level_id)
);

-- Create lessons table
CREATE TABLE IF NOT EXISTS public.lessons (
  id SERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  slug TEXT NOT NULL,
  objective TEXT,
  content TEXT,
  topic_id INTEGER NOT NULL REFERENCES public.topics(id) ON DELETE CASCADE,
  order_in_topic INTEGER NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(slug, topic_id)
);

-- Create cards table
CREATE TABLE IF NOT EXISTS public.cards (
  id SERIAL PRIMARY KEY,
  word TEXT NOT NULL,
  translation TEXT NOT NULL,
  ipa TEXT,
  audio_url TEXT,
  image_url TEXT,
  example_sentence TEXT,
  grammar_explanation TEXT,
  lesson_id INTEGER NOT NULL REFERENCES public.lessons(id) ON DELETE CASCADE,
  order_in_lesson INTEGER NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create user_progress table to track user learning progress
CREATE TABLE IF NOT EXISTS public.user_progress (
  id SERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  card_id INTEGER NOT NULL REFERENCES public.cards(id) ON DELETE CASCADE,
  ease_factor REAL NOT NULL DEFAULT 2.5,
  interval INTEGER NOT NULL DEFAULT 0,
  next_review_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  review_count INTEGER NOT NULL DEFAULT 0,
  last_reviewed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, card_id)
);

-- Create storage triggers to keep updated_at current
CREATE OR REPLACE FUNCTION public.update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = NOW();
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add triggers to all tables
CREATE TRIGGER update_languages_timestamp BEFORE UPDATE ON public.languages
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE TRIGGER update_language_levels_timestamp BEFORE UPDATE ON public.language_levels
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE TRIGGER update_topics_timestamp BEFORE UPDATE ON public.topics
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE TRIGGER update_lessons_timestamp BEFORE UPDATE ON public.lessons
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE TRIGGER update_cards_timestamp BEFORE UPDATE ON public.cards
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE TRIGGER update_user_progress_timestamp BEFORE UPDATE ON public.user_progress
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

-- Add RLS policies
ALTER TABLE public.languages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.language_levels ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.topics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_progress ENABLE ROW LEVEL SECURITY;

-- Public read access policies
CREATE POLICY "Allow public read access to languages" ON public.languages FOR SELECT USING (true);
CREATE POLICY "Allow public read access to language_levels" ON public.language_levels FOR SELECT USING (true);
CREATE POLICY "Allow public read access to topics" ON public.topics FOR SELECT USING (true);
CREATE POLICY "Allow public read access to lessons" ON public.lessons FOR SELECT USING (true);
CREATE POLICY "Allow public read access to cards" ON public.cards FOR SELECT USING (true);

-- User progress policies
CREATE POLICY "Users can view their own progress" ON public.user_progress 
  FOR SELECT USING (auth.uid() = user_id);
  
CREATE POLICY "Users can update their own progress" ON public.user_progress 
  FOR UPDATE USING (auth.uid() = user_id);
  
CREATE POLICY "Users can insert their own progress" ON public.user_progress 
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_language_levels_language_id ON public.language_levels(language_id);
CREATE INDEX IF NOT EXISTS idx_topics_language_level_id ON public.topics(language_level_id);
CREATE INDEX IF NOT EXISTS idx_lessons_topic_id ON public.lessons(topic_id);
CREATE INDEX IF NOT EXISTS idx_cards_lesson_id ON public.cards(lesson_id);
CREATE INDEX IF NOT EXISTS idx_user_progress_user_id ON public.user_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_user_progress_next_review ON public.user_progress(next_review_date); 