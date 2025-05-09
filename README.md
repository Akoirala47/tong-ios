# Tong Mobile Language Learning Application

Tong is an innovative mobile language learning app built with Swift (iOS) and Supabase backend. It features AI-powered feedback, real-time video chat, gamification, and a robust learning loop.

## Repository Structure

- `tong-ios/` — SwiftUI iOS app code
- `functions/` — Supabase Edge Functions (Deno/TypeScript)
- `supabase/` — Supabase project config and migrations
- `.vscode/` — VS Code settings (Deno enabled for Edge Functions)

## Getting Started

### Prerequisites
- Xcode (latest)
- [Supabase CLI](https://supabase.com/docs/guides/cli)
- [Deno](https://deno.com/)

### Setup
1. Clone the repo
2. Copy `.env.example` to `.env` and fill in secrets
3. Run `supabase start` to start local backend
4. Open `tong-ios` in Xcode and build/run

### Development
- Edge Functions: see `functions/README.md`
- iOS app: MVVM, SwiftUI, protocol-oriented, see `tong-ios/`

## CI/CD
- GitHub Actions for iOS and Supabase workflows (to be set up in `.github/workflows/`)

## License
MIT 