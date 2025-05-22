# Tong Language Learning Content Seeding

This directory contains the configuration files and tools for automatically generating language learning content for the Tong app using Gemini 2.0 Flash AI.

## Directory Structure

```
seed/
├── README.md             # This file
├── <language-code>/      # Language-specific directories (e.g., es, fr, ja)
    ├── config.yml        # Language configuration with ACTFL levels
    ├── vocab.csv         # High-frequency words (optional)
    └── logs/             # Generated content logs (automatically created)
```

## How It Works

The seeding pipeline uses Gemini 2.0 Flash to automatically generate ACTFL-aligned language lessons and flashcards based on "Can-Do" statements. The process:

1. Loads language configuration from `seed/<language-code>/config.yml`
2. Gets ACTFL "Can-Do" statements from `prompts/actfl_can_do.json`
3. Sends a prompt to Gemini 2.0 Flash to generate a batch of lessons
4. Validates the generated content using Zod schema
5. Inserts the content into the Supabase database
6. Logs all prompts and responses for auditing

## Usage

### Running the Seed Script

You can use the provided shell script:

```bash
# Generate content for Spanish, Novice Low level
./seed.sh --lang es --levels NL

# Generate content for multiple levels
./seed.sh --lang es --levels NL,NM,NH

# Generate content for all levels defined in config.yml
./seed.sh --lang es --levels all

# Generate using a specific Can-Do statement (by index)
./seed.sh --lang es --levels NL --can-do-index 1
```

Alternatively, you can run the TypeScript script directly:

```bash
# Navigate to functions directory
cd functions

# Install dependencies if not already installed
npm install

# Run the seeding script using ts-node
npx ts-node tools/seed.ts --lang es --levels NL --can-do-index 0
```

### Prerequisites

- Supabase project with the proper schema (see `supabase/migrations/`)
- Gemini API key (can be set in `.env` or passed via environment variables)
- Node.js and npm/pnpm

## Testing the Generated Content in the App

Once you've run the seeding script, the generated lessons and flashcards are stored in Supabase and can be accessed in the iOS app. To test the content:

1. Make sure you have applied all the database migrations in `supabase/migrations/`
2. Run the seeding script to generate content for the language of your choice
3. Launch the Tong iOS app and sign in
4. Navigate to the Home tab where the app will fetch and display the lessons
5. Browse through topics and lessons, and try the flashcard drills

## iOS Integration

The app uses the following components to display the seeded content:

- `LearningContent.swift`: Models for the lessons, flashcards, topics, etc.
- `SupabaseManager.swift`: Methods to fetch content from Supabase
- `FlashcardHomeViewModel.swift`: Manages content state for the UI
- `FlashcardHomeView.swift`: Displays lessons and topics
- `LessonDetailView.swift`: Displays lesson content and flashcards

## Adding a New Language

1. Create a new language directory: `mkdir -p seed/<language-code>`
2. Create a `config.yml` file with the language configuration
3. Optionally add a `vocab.csv` file with high-frequency words
4. Run the seed script: `./seed.sh --lang <language-code> --levels NL`
5. Add the language to the Supabase database using a migration:

```sql
INSERT INTO languages (code, name, native_name, created_at)
VALUES ('<code>', '<English name>', '<Native name>', now())
ON CONFLICT (code) DO NOTHING;
```

## Content Structure

Each generated batch contains:
- 1 topic derived from an ACTFL Can-Do statement
- 6 lessons per topic
- 8-12 flashcards per lesson
- Each flashcard has a word/phrase, translation, IPA pronunciation, and example sentence 