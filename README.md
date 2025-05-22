# Tong Language Learning App

Tong is a modern language learning app designed to help users learn languages effectively through spaced repetition flashcards, interactive lessons, pronunciation practice, and social learning features.

## Features

- **Self-paced learning**: Structured lessons and topics organized by proficiency level
- **Spaced Repetition System**: Intelligent flashcard review schedule based on performance
- **Pronunciation practice**: Record and receive feedback on pronunciation
- **Social learning**: Compete with friends and practice with native speakers
- **Progress tracking**: Track streaks, XP, and learning milestones

## Technical Architecture

### Backend (Supabase)

- **Authentication**: User accounts and profiles
- **Database**: PostgreSQL database for curriculum, flashcards, and user progress
- **Storage**: Audio recordings and images for flashcards
- **Edge Functions**: Server-side processing for curriculum management and AI features

### iOS App (Swift/SwiftUI)

- **Architecture**: MVVM (Model-View-ViewModel)
- **UI Framework**: SwiftUI
- **Data Flow**: Combine for reactive programming
- **Networking**: Supabase Swift client
- **Local Storage**: CoreData for offline access

## Database Schema

The app uses the following database tables:

- `languages`: Available languages (Spanish, French, etc.)
- `language_levels`: Proficiency levels (Novice, Intermediate, Advanced)
- `topics`: Learning topics within each level
- `lessons`: Individual lessons within topics
- `cards`: Flashcards with vocabulary, examples, and media
- `user_progress`: Tracks user progress through spaced repetition algorithm

## Setup Instructions

### Prerequisites

- Xcode 14+ 
- iOS 15+
- Swift 5.5+
- A Supabase account

### Installation

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/tong-ios.git
   cd tong-ios
   ```

2. Install dependencies:
   ```
   swift package resolve
   ```

3. Open the project in Xcode:
   ```
   open tong-ios.xcodeproj
   ```

4. Set up your Supabase credentials:
   - Create a `.env` file in the project root
   - Add your Supabase URL and anon key:
     ```
     SUPABASE_URL=https://your-project-id.supabase.co
     SUPABASE_ANON_KEY=your-anon-key
     ```

5. Run the app in the simulator or on a device.

### Seeding Data

To populate the database with initial language data:

1. Run the seeding script:
   ```
   node direct-seed-spanish.js
   ```

2. This will populate the database with Spanish language curriculum data including levels, topics, lessons, and flashcards.

## Architecture

The app follows MVVM architecture:

- **Models**: Data structures matching the Supabase schema
- **Views**: SwiftUI views for UI representation
- **ViewModels**: Business logic and state management

## Contributors

- [Your Name](https://github.com/yourusername) - Lead Developer 