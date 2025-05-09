# Supabase Edge Functions

This directory contains all Supabase Edge Functions for the Tong app backend. Edge Functions are written in Deno/TypeScript and deployed to Supabase for serverless execution.

## Structure
- Place each function in its own subdirectory.
- Use clear, descriptive names for each function.

## Development
- Requires [Deno](https://deno.com/) and the [Supabase CLI](https://supabase.com/docs/guides/cli).
- Use VS Code with the Deno extension for best experience (see `.vscode/settings.json`).

## Running Locally
- Use `supabase functions serve` to run and test functions locally.

## Deployment
- Use `supabase functions deploy <function_name>` to deploy to Supabase.

---

For more details, see the [Supabase Edge Functions documentation](https://supabase.com/docs/guides/functions). 