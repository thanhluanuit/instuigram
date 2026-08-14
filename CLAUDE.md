# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

Instuigram is an Instagram clone built as a learning project for Ruby on Rails fundamentals (MVC, Active Record associations/validations/callbacks, Devise auth, Active Storage uploads, Kaminari pagination, Bootstrap views). It is a small, intentionally minimal Rails app — not a production system.

## Tech stack

- **Ruby 3.3.11, Rails 8.0.5.1** (`config.load_defaults 8.0`) — reached via staged upgrades, one Rails minor/major at a time via `bin/rails app:update` + a `load_defaults` bump per step; see git log for the exact commit sequence when repeating this pattern for a future major. The last hop (7.2 → 8.0, forced by 7.2 going EOL) is worth double-checking by hand next time: `app:update` silently dropped several `config/environments/production.rb` settings that Rails 8's template no longer includes by default (`require_master_key`, and the Sprockets-specific `js_compressor`/`assets.compile`/`public_file_server` lines, since Rails 8's template assumes Propshaft) — review its diff line-by-line rather than trusting it wholesale.
- Managed via RVM; `.ruby-version` / `.ruby-gemset` are committed (`ruby-3.3.11@instuigram`). See "Known environment gotchas" below for the Ruby 3.4/`mutex_m` tradeoff that keeps us on 3.3.x.
- **PostgreSQL** (`development_instuigram` / `test_instuigram` / `production_instuigram`, see `config/database.yml`) — no version-specific SQL, so any modern Postgres works locally despite the README mentioning 9.6.
- **Devise** for auth, **Kaminari** for pagination, **Active Storage** for image uploads (avatars, post images).
- **Bootstrap 4.6.x** (CSS only, no jQuery), SCSS via the classic Sprockets pipeline; **Turbo** + **Stimulus** for JS via **importmap-rails** (required by turbo-rails' no-npm install path) — JS and CSS intentionally go through two different asset mechanisms.
- Secrets live in Rails encrypted credentials (`config/credentials.yml.enc` + gitignored `config/master.key`), not `config/secrets.yml`.

`.claude/rules/technical_stack.md` is the terse, exact-version reference for this stack; this section is the narrative (why these versions, the upgrade path). Update both together when a version changes — they've drifted out of sync before (Bootstrap).

## Common commands

```bash
bundle install                 # install gems
bin/rails db:create db:migrate # set up the database
bin/rails db:migrate RAILS_ENV=test  # migrate the test database
bin/rails server                # run the app (default http://localhost:3000)
bin/rails console               # REPL
bin/rails test                  # run the Minitest suite (test/)
bin/rails test test/models/post_test.rb            # run a single test file
bin/rails test test/models/post_test.rb:7          # run a single test at a line
bin/rails test:system           # run Capybara/Selenium system tests
```

- **RuboCop**: `rubocop-rails-omakase` (Rails 8's own default style, inherited wholesale in `.rubocop.yml` with no project-specific overrides) — run `bundle exec rubocop` (`-A` to autofix).
- No JS package dependencies — `package.json` has an empty `dependencies` object.

## CI

GitHub Actions (`.github/workflows/ci.yml`) runs on every push/PR to `master`: spins up a `postgres:15` service container, runs `bundle exec brakeman`, `bundle exec bundle-audit check --update`, and `bundle exec rubocop`, then `bin/rails db:schema:load` against `test_instuigram` and `bin/rails test`.

## Known environment gotchas

- **Native gem compilation on modern Xcode (15+)**: RVM-built Rubies on this machine bake in linker flags (`-Wl,-z,relro,-z,now`) that the newer Xcode `ld` linker rejects, breaking `bundle install` for any gem with a C extension (nio4r, ffi, pg, etc.) with a "C compiler cannot create executables" error. Fix: `export LDFLAGS="-Wl,-ld_classic"` before running `bundle install`.
- **Don't bump past Ruby 3.3.x without checking `mutex_m`.** Ruby 3.4 dropped `mutex_m` from default gems, and `spring`'s file watcher requires it — bumping to 3.4+ needs an explicit `gem 'mutex_m'` added back to the Gemfile (deliberately avoided here by staying on 3.3.11).
- The `logger < 1.6` pin and the explicit `require 'logger'` workaround in `config/boot.rb` that earlier Rails 6.0/6.1 versions of this app needed are gone as of the Rails 7.2 upgrade — that bug was specific to Rails 6.0/6.1's `ActiveSupport::Logger` internals and doesn't apply here. No action needed; noted only so it isn't reintroduced by habit.
- **Don't reintroduce `uglifier` as the JS compressor.** It wraps the ES5-only UglifyJS2 and can't parse ES6+ syntax (e.g. `const`, spread/rest params) — Rails' own bundled JS (rails-ujs historically, ActionCable's `action_cable.js`) ships with exactly that syntax, so `uglifier` aborted `bin/rails assets:precompile RAILS_ENV=production` outright (discovered while removing Turbolinks/jQuery — this was already broken on `master` beforehand, unrelated to that change). Fixed by swapping to `gem "terser"` + `config.assets.js_compressor = :terser` in `config/environments/production.rb`.

## Architecture

Standard Rails MVC with a very small surface area — every model and controller lives directly under `app/models` / `app/controllers` (no nested namespaces).

**Domain model** (see `db/schema.rb` for full column list):
- `User` — Devise-authenticated (`database_authenticatable, registerable, recoverable, rememberable, trackable, validatable`; confirmable intentionally not enabled). Has many `posts` (`dependent: :destroy`) and `has_one_attached :avatar`.
  - `website` is validated against `URI::DEFAULT_PARSER.make_regexp(%w[http https])` (scoped to `http`/`https`, not the generic URI grammar) and rendered via `UsersHelper#external_url` — which re-parses through `URI.parse` and only returns the URL when it's `URI::HTTP`, `nil` otherwise — rather than linked raw.
  - Both layers close an XSS hole: an earlier version used the unscoped `make_regexp` and had `external_url` rescue only `URI::InvalidURIError`. `URI.parse` doesn't raise on `javascript:`/`data:` schemes, so a syntactically-valid `javascript:` URI in `website` passed both checks and executed on profile view (`app/views/users/show.html.erb`). Scheme must be allow-listed explicitly, never inferred from parse success.
  - Don't reintroduce a raw `link_to @user.website, @user.website`, and don't loosen the model's scheme allow-list or the helper's `URI::HTTP` check back to a bare `URI.parse`/rescue.
- `Post` — belongs to `User`, `has_one_attached :image`. Validates that an image is attached. On create, an `after_commit :create_hash_tags` callback parses `#word` tokens out of `description` via regex and creates associated `HashTag` records — this is how hashtag search works, there is no separate tagging UI.
- `HashTag` / `PostHashTag` — join model implementing a many-to-many between `Post` and `HashTag`.

**Controllers/routes** (`config/routes.rb`):
- `root` → `HomeController#index` — the feed; redirects to sign-in if no `current_user`; paginates posts 5-per-page with Kaminari.
- `devise_for :users` — standard Devise routes (sessions, registrations, password reset).
- `resources :users, only: [:show, :edit, :update]` — profile view/edit; `edit`/`update` require authentication via `before_action :authenticate_user!`.
- `resources :posts, only: [:create, :show, :destroy]` — `PostsController` requires authentication for everything except `show` (`before_action :authenticate_user!, except: [:show]`); `create` attributes the post to `current_user` (never a client-supplied `user_id`), and `destroy` is scoped through `current_user.posts.find(...)` so users can only delete their own posts.
- `get 'search'` → `SearchController#index` — dispatches on whether `params[:query]` starts with `#`: hashtag lookups join through `hash_tags`, otherwise it's a `LIKE` match against `description`, with the term run through `Post.sanitize_sql_like` before interpolation into the `%...%` pattern — required because a parameterized `LIKE` is still exploitable at the wildcard level (`%`/`_` in `params[:query]` would otherwise turn a lookup into a full scan). Keep this wrapper if this query is ever touched again.

Views are server-rendered ERB under `app/views/{home,posts,search,users}`, sharing `app/views/layouts/application.html.erb`, with partials for reusable pieces (e.g. `home/_post`, `home/_upload_form`, `posts/_description`).
