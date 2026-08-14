# Technical Stack

## Runtime

- **Ruby**: 3.3.11 (pinned in `.ruby-version` / `.ruby-gemset`, managed via RVM)
- **Rails**: 8.0.5.1 (`config.load_defaults 8.0`)
- **Package manager**: Bundler 2.4.22

## Data

- **Primary database**: PostgreSQL (see `config/database.yml`; no version-specific SQL, so any reasonably modern Postgres works)
- **Cache / sessions**: Rails defaults, not explicitly configured — dev uses `:memory_store`, production has no `cache_store` set and uses Rails' default cookie-based session
- **Background jobs**: none — no queue adapter configured
- **Search**: none — hashtag/description search in `SearchController` is a plain `LIKE` query

## Application

- **Authentication**: Devise (`database_authenticatable, registerable, recoverable, rememberable, trackable, validatable`; confirmable intentionally not enabled)
- **Authorization**: none — no Pundit/CanCanCan; done ad hoc in controllers (e.g. scoping `current_user.posts.find(...)`)

## Frontend

- **Rendering**: server-rendered ERB views (no ViewComponent) with Turbo Drive (`turbo-rails`) for page acceleration and Stimulus (`stimulus-rails`) for the small amount of client-side behavior (e.g. `app/javascript/controllers/tabs_controller.js`). No jQuery — dropped along with Bootstrap's JS bundle; Bootstrap is CSS-only now.
- **Asset pipeline**: Sprockets owns CSS (classic Rails asset pipeline, not Propshaft/webpacker/jsbundling — `package.json` has no dependencies) and non-JS assets; `importmap-rails` owns all JS (Turbo, Stimulus, app controllers) — added because `turbo-rails`'s no-npm install path requires it. The two coexist normally; this isn't a conflict, just two asset-delivery mechanisms doing different jobs.
- **JS compressor**: `terser`, not `uglifier` — `uglifier` wraps the ES5-only UglifyJS2 and can't parse the ES6+ syntax Rails' own bundled JS (rails-ujs historically, ActionCable) ships with; it aborted `assets:precompile` outright. `terser` handles modern JS natively.
- **CSS**: SCSS via `sassc-rails`, with Bootstrap 4.6.x

## Testing & quality

- **Test framework**: Minitest (Rails default) — `test/` has `models`, `controllers`, `integration`, `system`, `mailers`, `helpers`
- **Factories / fixtures**: fixtures (`test/fixtures/*.yml`) — no FactoryBot
- **Linters**: RuboCop, via `rubocop-rails-omakase` (Rails 8's own default style — inherited wholesale in `.rubocop.yml` via `inherit_gem`, no project-specific overrides yet). Run locally with `bundle exec rubocop` (`-A` to autofix); enforced as a CI step. No ERB Lint.
- **Security scanners**: Brakeman (`development, test` group in the Gemfile, `require: false`), run via `bundle exec brakeman` locally and as a CI step (`.github/workflows/ci.yml`); all confidence levels (Weak/Medium/High) fail the build, no `-w` filter. No `config/brakeman.ignore.json` exists yet (there's nothing to baseline — Brakeman currently reports 0 warnings); if a future false positive needs suppressing, baseline it there with a justification note (`brakeman -I` generates the file) rather than raising `-w`. `bundler-audit` (same Gemfile group, `require: false`) flags gems with known CVEs against the `ruby-advisory-db`; run locally via `bundle exec bundle-audit check --update` (the `--update` refreshes the advisory DB first) and enforced as a CI step alongside Brakeman — see [`security.md`](security.md).

## Conventions for keeping this file honest

- Bump the versions here in the same PR that bumps them in `Gemfile.lock`.
- If a listed tool is removed, remove it here too — a stale stack doc is worse
  than none.
