# Forge Workout Tracker

Forge is an early workout-tracking product prototype. The GitHub Pages site is a browser PWA that can store data locally or sync completed workouts and routines to Supabase after sign-in.

## Product foundation

- Browser client and PWA: this repository's `index.html`, `app.js`, and `style.css`.
- Hosted backend: Supabase project `bfwuuxamiuapfuxzfieu` in `ap-south-1`, with versioned schema in `supabase/migrations/` for auth profiles, exercise videos, routines, workout sets, exercise comments, and like/dislike reactions.
- Access rules: all exposed tables have row-level security and explicit client grants. User workouts and routines are private by owner; public exercise content is read-only to clients.
- Video variants: each exercise supports an `ai_generated` and a `team_demo` video record.
- Exercise videos are browsable from the Exercises page and served by the public Supabase Storage `exercise-videos` bucket. Add an approved video row after uploading a file; see [Supabase setup](supabase/README.md).

The browser client uses the project's public publishable key from `cloud.js`. Never put a service-role key or OAuth secret in browser code or the repository. Email/password sign-in is wired. Google and Apple buttons need provider credentials configured in Supabase before those options can complete sign-in. See [Supabase setup](supabase/README.md).

## Run the current PWA locally

Serve the project over `localhost` or HTTPS (for example with the VS Code Live Server extension). Opening a local `file://` URL can prevent browser auth redirects. Without sign-in, data stays in that browser's `localStorage`; after sign-in, routines and completed workouts sync to the account.

For install prompts and offline caching, serve the project from `localhost` or HTTPS. The app can then be installed from the browser's menu or install button.

## Deploy the current PWA to GitHub Pages

The workflow in `.github/workflows/pages.yml` deploys the site when changes are pushed to `main`. In the repository, enable **Settings → Pages → Build and deployment → GitHub Actions** if Pages is not already configured.

The Pages URL is `https://sainath-web.github.io/forge-workout-tracker/`. Add this URL to the Supabase Auth Site URL and redirect URL allow list to use email confirmations and OAuth from the deployed site.
