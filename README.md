# Forge Workout Tracker

A free, mobile-friendly workout tracker that runs in the browser. Log sessions, build routines, review exercise history and personal records, and export your data.

## Run locally

Open `index.html` in a browser. Data is stored locally in that browser using `localStorage`.

For install prompts and offline caching, serve the project from `localhost` or HTTPS. The app can then be installed from the browser's menu or install button.

## Deploy to GitHub Pages

The workflow in `.github/workflows/pages.yml` deploys the site when changes are pushed to `main`. In the repository, enable **Settings → Pages → Build and deployment → GitHub Actions** if Pages is not already configured.

The Pages URL will be `https://sainath-web.github.io/forge-workout-tracker/` after the first successful deployment. Each visitor's workout data stays in their own browser; this version does not sync data between devices.

