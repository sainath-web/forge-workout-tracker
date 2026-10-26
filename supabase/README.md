# Supabase backend setup

This folder holds Forge's database schema as versioned Supabase migrations. The active project is `bfwuuxamiuapfuxzfieu` in `ap-south-1`. The client uses only the public publishable key in `cloud.js`; never put a service-role key or OAuth secret in browser code or the repository.

## Current schema

- Supabase Auth identities plus public profiles.
- Published exercise catalogue and two exercise video variants: `ai_generated` and `team_demo`.
- Per-user routines and workout history with exercise sets.
- Exercise comments and one like/dislike reaction per user and exercise.
- Row-level security on every exposed table. A user can only access their own profile edits, routines, workouts, and sets. Public exercise data, approved exercise videos, visible comments, and aggregate reaction counts are readable without exposing the reaction voter list.
- The current frontend supports email/password auth, syncing routines and completed workout logs, and browsing approved exercise demonstrations from Supabase Storage. Comments, reactions, and social provider configuration are still future app work.

## Exercise videos

The public `exercise-videos` bucket allows MP4 and WebM files up to 20 MB. Upload the clip in Supabase Storage, then add an `approved` row to `public.exercise_videos` with the exercise ID, `kind` (`team_demo` or `ai_generated`), title, `provider='supabase_storage'`, and the file's public URL in `playback_url`. The app's Exercises page reads only approved rows under the existing RLS policy. A public bucket means anyone with the file URL can watch the video.

## Current app setup

The schema and function-grant migrations are already applied to the hosted project. The Pages workflow publishes `cloud.js` alongside the PWA files. Email sign-up may require a confirmation link.

In Supabase **Authentication → URL Configuration**, set the Site URL to `https://sainath-web.github.io/forge-workout-tracker/` and include that URL in the redirect allow list. For local development, also allow your localhost origin. Google and Apple sign-in buttons require their OAuth client credentials entered in **Authentication → Providers**. Keep provider secrets in Supabase settings; do not paste them into this repository or chat.

When changing the schema, create a new migration with the Supabase CLI and apply it to a development project before production. The existing hosted migrations were applied through the connected Supabase integration; their remote version identifiers are reflected in the filenames in `migrations/`.
