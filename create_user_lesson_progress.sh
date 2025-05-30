#!/bin/bash

SQL_MIGRATION="CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";

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

CREATE INDEX IF NOT EXISTS idx_user_lesson_progress_user_id ON public.user_lesson_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_user_lesson_progress_lesson_id ON public.user_lesson_progress(lesson_id);
CREATE INDEX IF NOT EXISTS idx_user_lesson_progress_completed ON public.user_lesson_progress(completed);

ALTER TABLE public.user_lesson_progress ENABLE ROW LEVEL SECURITY;

CREATE POLICY \"Anon can view all lesson progress\"
    ON public.user_lesson_progress
    FOR SELECT
    TO anon
    USING (true);

CREATE POLICY \"Anon can insert lesson progress\"
    ON public.user_lesson_progress
    FOR INSERT
    TO anon
    WITH CHECK (true);

CREATE POLICY \"Anon can update lesson progress\"
    ON public.user_lesson_progress
    FOR UPDATE
    TO anon
    USING (true);"

# Remove all newlines to make it a single line
SQL_MIGRATION_SINGLE_LINE=$(echo "$SQL_MIGRATION" | tr '\n' ' ')

curl -X POST https://eexuddpbzkqtvwfeurml.supabase.co/rest/v1/rpc/execute_sql \
  -H "apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVleHVkZHBiemtxdHZ3ZmV1cm1sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDY4MTcxMTYsImV4cCI6MjA2MjM5MzExNn0.HdkzTzN5t_y7LFhWrdefNagaFPDihvmB42rIRscFapo" \
  -H "Content-Type: application/json" \
  --data "{\"sql\": \"$SQL_MIGRATION_SINGLE_LINE\"}" 