# Technical Stack

## Runtime

- **Ruby**: 3.3.11 (pinned in `.ruby-version` / `.ruby-gemset`, managed via RVM)
- **Rails**: 8.1.3.1 (`config.load_defaults 8.1`)
- **Package manager**: Bundler 2.4.22

## Data

- **Primary database**: PostgreSQL (see `config/database.yml`; no version-specific SQL, so any reasonably modern Postgres works)
- **Cache / sessions**: `config.cache_store = :redis_cache_store` in both development and production (`config/environments/{development,production}.rb`), pointed at `ENV.fetch("REDIS_CACHE_URL", "redis://localhost:6379/2")` — DB 2, kept separate from Sidekiq/ActionCable's DB 1 to avoid cache keys colliding with queue/pub-sub data. Deliberately not DB 0 either: on a shared local Redis instance, DB 0 is Sidekiq's own out-of-the-box default, so it's the index most likely to already be claimed by an unrelated project. Test stays `:null_store`. Sessions use Rails' default cookie-based session, not explicitly configured.
- **Background jobs**: Sidekiq (`gem "sidekiq"`, `config.active_job.queue_adapter = :sidekiq` in `config/application.rb`), backed by the same Redis server via `ENV.fetch("REDIS_URL", "redis://localhost:6379/1")` (`config/initializers/sidekiq.rb`)
- **Search**: Elasticsearch 8.x (`elasticsearch-model` + `elasticsearch-rails`, `~> 8.0` — the official, lower-level gems, not Searchkick), via `docker-compose.yml` locally, pointed at `ENV.fetch("ELASTICSEARCH_URL", "http://localhost:9200")` (`config/initializers/elasticsearch.rb`).

## Application

- **Authentication**: Devise (`database_authenticatable, registerable, recoverable, rememberable, trackable, validatable`; confirmable intentionally not enabled)
- **Authorization**: none — no Pundit/CanCanCan; done ad hoc in controllers (e.g. scoping `current_user.posts.find(...)`)
- **Image variants**: Active Storage **named** variants, declared in the `has_one_attached` block on the model and referenced by name in views (`.variant(:thumb)`) — never with inline dimensions, which previously drifted to nine distinct avatar derivatives across the view layer. `User#avatar` declares `:thumb` (112²) and `:large` (280²), both `preprocessed: true`; `Post#image` declares `:feed` (600), `:detail` (1200) and `:thumb` (440²), all lazy. Display size is owned by CSS — the `avatar($size)` mixin in `app/assets/stylesheets/components/_avatar.scss` sizes the container and `object-fit: cover`s the image — so a variant only picks source resolution; pick the band that keeps every call site at ≥2x its CSS size rather than adding a variant per call site. Backed by `gem "image_processing"` + `gem "mini_magick"`, with `config.active_storage.variant_processor = :mini_magick` in `config/application.rb` — Rails' own default is `:vips`, which needs the `ruby-vips` gem this app doesn't have; `mini_magick` shells out to the ImageMagick `mogrify`/`convert` binaries instead.

## Frontend

- **Rendering**: server-rendered ERB views (no ViewComponent) with Turbo Drive (`turbo-rails`) for page acceleration and Stimulus (`stimulus-rails`) for the small amount of client-side behavior (e.g. `app/javascript/controllers/tabs_controller.js`). No jQuery — dropped along with Bootstrap's JS bundle; Bootstrap is CSS-only now.
- **Asset pipeline**: Sprockets owns CSS (classic Rails asset pipeline, not Propshaft/webpacker/jsbundling — `package.json` has no dependencies) and non-JS assets; `importmap-rails` owns all JS (Turbo, Stimulus, app controllers) — added because `turbo-rails`'s no-npm install path requires it. The two coexist normally; this isn't a conflict, just two asset-delivery mechanisms doing different jobs.
- **JS compressor**: `terser`, not `uglifier` — `uglifier` wraps the ES5-only UglifyJS2 and can't parse the ES6+ syntax Rails' own bundled JS (rails-ujs historically, ActionCable) ships with; it aborted `assets:precompile` outright. `terser` handles modern JS natively.
- **CSS**: SCSS via `sassc-rails`, with Bootstrap 5.3.x. Design tokens live in `app/assets/stylesheets/_tokens.scss` (a warm vintage palette — cream canvas, burnt-orange primary, navy ink — taken from the Claude Design "Feed Section" artboard); `_bootstrap_overrides.scss` aliases Bootstrap's variables onto them before Bootstrap loads. `components/_app_shell.scss` holds the layout-level shell (`.app-shell`, `.app-rail`) every page renders; page stylesheets under `pages/` own only their own content and no longer set a top margin, since the shell does.
- **Webfonts**: Righteous (display), Rubik (body) and Space Mono (meta) are **self-hosted** as woff2 under `app/assets/fonts`, declared in `base/_typography.scss` via `font-url` and precompiled through `//= link_tree ../fonts`. They are deliberately not loaded from `fonts.googleapis.com` — `config/initializers/content_security_policy.rb` sets `style_src :self` / `font_src :self, :data`, which blocks it. Rubik ships one variable file per subset covering weights 400–700. Neither Rubik nor Righteous publishes a Vietnamese subset, so Vietnamese text falls back to the system stack.

## Testing & quality

- **Test framework**: Minitest (Rails default) — `test/` has `models`, `controllers`, `integration`, `system`, `mailers`, `helpers`
- **System tests**: Capybara + Selenium, headless Chrome by default (`HEADED=1` for a real window), run in CI by their own `system_test` job via `bin/rails test:system` — `bin/rails test` excludes `test/system` by Rails' default glob, so the two jobs cover disjoint sets
- **Coverage**: SimpleCov (`SimpleCov.start "rails"` in `test/test_helper.rb`, before any app code loads), report-only — generates `coverage/index.html` locally on every `bin/rails test` run and prints the summary % to CI's `test` job log; no enforced minimum yet.
- **Factories / fixtures**: fixtures (`test/fixtures/*.yml`) — no FactoryBot
- **Linters**: RuboCop, via `rubocop-rails-omakase` (Rails 8's own default style — inherited wholesale in `.rubocop.yml` via `inherit_gem`, no project-specific overrides yet). Run locally with `bundle exec rubocop` (`-A` to autofix); enforced as a CI step. No ERB Lint.
- **Security scanners**: Brakeman (`development, test` group in the Gemfile, `require: false`), run via `bundle exec brakeman` locally and as a CI step (`.github/workflows/ci.yml`); all confidence levels (Weak/Medium/High) fail the build, no `-w` filter. No `config/brakeman.ignore.json` exists yet (there's nothing to baseline — Brakeman currently reports 0 warnings); if a future false positive needs suppressing, baseline it there with a justification note (`brakeman -I` generates the file) rather than raising `-w`. `bundler-audit` (same Gemfile group, `require: false`) flags gems with known CVEs against the `ruby-advisory-db`; run locally via `bundle exec bundle-audit check --update` (the `--update` refreshes the advisory DB first) and enforced as a CI step alongside Brakeman — see [`security.md`](security.md).

## Developer tooling

- **Model schema annotations**: `annotaterb` 4.24.0 (`gem "annotaterb", require: false`, `group :development` only — `require: false` matches `brakeman`/`bundler-audit`/`rubocop-rails-omakase`, since the rake task requires it explicitly and nothing else needs it at boot). The maintained fork of the unmaintained `annotate` gem, which last shipped in 2021 and breaks on Rails 7.1+. Writes the `# == Schema Information` block (columns, types, defaults, indexes, foreign keys, check constraints) above each `app/models/*.rb` class, introspecting the **live database** rather than `db/schema.rb` — the gem offers no option to read the schema file. `.annotaterb.yml` deliberately carries **only the five keys that differ from the gem's defaults**: `exclude_tests`, `exclude_fixtures`, `exclude_factories`, `exclude_serializers` (all `true`, which is what restricts annotation to models) and `show_check_constraints: true` (off by default, but this schema backs `Follow#not_self_follow` with a `follows_no_self_follow` check constraint that would otherwise be invisible in the model). Position `before`, `classified_sort`, `show_indexes`, `show_foreign_keys` and `routes: false` are already gem defaults and are not restated — `bin/rails g annotate_rb:config` dumps all ~62 keys, which buries the ones that matter. `lib/tasks/annotate_rb.rake` hooks `db:migrate`/`db:rollback` so annotations can't drift locally; skip with `ANNOTATERB_SKIP_ON_DB_TASKS=1`. Regenerate by hand with `bundle exec annotaterb models`; CI's `test` job re-runs it and fails on any diff, so a stale annotation can't merge. The blocks are generated, never authored — see the carve-out in [`code_style.md`](code_style.md)'s otherwise-absolute "no comments in code" rule.

## Conventions for keeping this file honest

- Bump the versions here in the same PR that bumps them in `Gemfile.lock`.
- If a listed tool is removed, remove it here too — a stale stack doc is worse
  than none.
