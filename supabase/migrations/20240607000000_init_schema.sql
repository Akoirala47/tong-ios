-- Tong App Initial Schema Migration

-- 1. profiles table
create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique,
  email text,
  elo integer default 1000,
  streak integer default 0,
  level integer default 1,
  is_pro boolean default false,
  stripe_subscription_id text,
  stripe_customer_id text,
  subscription_expires_at timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- 2. languages table
create table if not exists languages (
  id serial primary key,
  code text unique not null,
  name text not null
);

-- 3. topics table
create table if not exists topics (
  id uuid primary key default uuid_generate_v4(),
  language_id integer references languages(id),
  name text not null
);

-- 4. lessons table (note: possibly already created in earlier migration)
DO $$
BEGIN
  -- Add topic_id column to lessons if it doesn't exist
  IF EXISTS (SELECT FROM pg_tables WHERE tablename = 'lessons') AND 
     NOT EXISTS (SELECT FROM information_schema.columns 
                WHERE table_name = 'lessons' AND column_name = 'topic_id') THEN
    ALTER TABLE lessons ADD COLUMN topic_id uuid REFERENCES topics(id);
  END IF;
END
$$;

-- 5. cards table
create table if not exists cards (
  id uuid primary key default uuid_generate_v4(),
  lesson_id uuid references lessons(id),
  word text not null,
  translation text,
  image_url text,
  audio_url text,
  grammar_explanation text
);

-- 6. card_reviews table (SRS)
create table if not exists card_reviews (
  id uuid primary key default uuid_generate_v4(),
  card_id uuid references cards(id),
  user_id uuid references profiles(id),
  next_review_date date,
  interval integer,
  ease_factor real,
  last_reviewed_at timestamptz,
  created_at timestamptz default now()
);

-- 7. xp_events table
create table if not exists xp_events (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references profiles(id),
  xp integer not null,
  event_type text,
  created_at timestamptz default now()
);

-- 8. daily_streaks table
create table if not exists daily_streaks (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references profiles(id),
  date date not null,
  streak integer default 0,
  created_at timestamptz default now(),
  unique(user_id, date)
);

-- 9. Enable Row Level Security (RLS) and policies
alter table profiles enable row level security;
alter table card_reviews enable row level security;
alter table xp_events enable row level security;
alter table daily_streaks enable row level security;

-- Only allow users to select/update their own profile
create policy "Users can view their own profile" on profiles
  for select using (auth.uid() = id);
create policy "Users can update their own profile" on profiles
  for update using (auth.uid() = id);

-- Only allow users to access their own card_reviews
create policy "Users can view their own card_reviews" on card_reviews
  for select using (auth.uid() = user_id);
create policy "Users can insert their own card_reviews" on card_reviews
  for insert with check (auth.uid() = user_id);
create policy "Users can update their own card_reviews" on card_reviews
  for update using (auth.uid() = user_id);

-- Only allow users to access their own xp_events
create policy "Users can view their own xp_events" on xp_events
  for select using (auth.uid() = user_id);
create policy "Users can insert their own xp_events" on xp_events
  for insert with check (auth.uid() = user_id);

-- Only allow users to access their own daily_streaks
create policy "Users can view their own daily_streaks" on daily_streaks
  for select using (auth.uid() = user_id);
create policy "Users can insert their own daily_streaks" on daily_streaks
  for insert with check (auth.uid() = user_id);
create policy "Users can update their own daily_streaks" on daily_streaks
  for update using (auth.uid() = user_id); 