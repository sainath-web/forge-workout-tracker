# Supabase backend setup

This folder holds Forge's database schema as a versioned Supabase migration. It is safe to commit; it contains no project URL, API key, service-role key, OAuth secret, or user data.

## Current schema

- Supabase Auth identities plus public profiles.
- Published exercise catalogue and two exercise video variants: `ai_generated` and `team_demo`.
- Per-user routines and workout history with exercise sets.
- Exercise comments and one like/dislike reaction per user and exercise.
- Row-level security on every exposed table. A user can only access their own profile edits, routines, workouts, and sets. Public exercise data, approved exercise videos, visible comments, and aggregate reaction counts are readable without exposing the reaction voter list.

## Apply to a hosted project

1. Create a Supabase project in your account and choose a region close to your users.
2. In the project settings, configure Auth providers and the callback/redirect URLs for the deployed site and mobile app. Do not send provider secrets in chat or commit them.
3. Install the Supabase CLI and link this project from your own terminal with `supabase link`.
4. Review the migration, then apply it with `supabase db push`.
5. Add only the project URL and public anon/publishable key to the client configuration. Keep the service-role key server-side and out of the web app.

The migration is not applied to a live database yet. Once a Supabase project exists, apply it first to a development project and verify the access policies before connecting the app.

