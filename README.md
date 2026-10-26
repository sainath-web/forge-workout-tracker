# Forge Workout Tracker

Forge is an early workout-tracking product prototype. The current Pages site is a browser PWA; it stores data locally and does not yet have customer accounts or cloud sync.

## Product foundation

- Browser client and PWA: this repository's `index.html`, `app.js`, and `style.css`.
- Hosted backend foundation: versioned Supabase schema in `supabase/migrations/` for auth profiles, exercise videos, routines, workout sets, exercise comments, and like/dislike reactions.
- Access rules: all exposed tables have row-level security and explicit client grants. User workouts and routines are private by owner; public exercise content is read-only to clients.
- Video variants: each exercise supports an `ai_generated` and a `team_demo` video record.

The first database migration is a reviewed starting schema only. It has not been applied to a live Supabase project. See [Supabase setup](supabase/README.md) before connecting a project. Never put a service-role key or OAuth secret in browser code or the repository.

## Run the current PWA locally

Open `index.html` in a browser. Data is stored locally in that browser using `localStorage`.

For install prompts and offline caching, serve the project from `localhost` or HTTPS. The app can then be installed from the browser's menu or install button.

## Deploy the current PWA to GitHub Pages

The workflow in `.github/workflows/pages.yml` deploys the site when changes are pushed to `main`. In the repository, enable **Settings → Pages → Build and deployment → GitHub Actions** if Pages is not already configured.

The Pages URL is `https://sainath-web.github.io/forge-workout-tracker/`. Until the hosted backend is configured and the client is connected, each visitor's workout data stays in their own browser.

