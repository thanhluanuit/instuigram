# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

Instuigram is an Instagram clone built as a learning project for Ruby on Rails fundamentals (MVC, Active Record associations/validations/callbacks, Devise auth, Active Storage uploads, Kaminari pagination, Bootstrap views). It is a small, intentionally minimal Rails app — not a production system.

`docs/superpowers/plans/` holds implementation plans for non-trivial changes (e.g. this project's staged Rails upgrades).

## Tech stack

- **Ruby 3.3.11, Rails 8.1.3.1** (`config.load_defaults 8.1`) — reached via staged upgrades, one Rails minor/major at a time via `bin/rails app:update` + a `load_defaults` bump per step; see git log for the exact commit sequence when repeating this pattern for a future major. The 7.2 → 8.0 hop (forced by 7.2 going EOL) is worth double-checking by hand next time: `app:update` silently dropped several `config/environments/production.rb` settings that Rails 8's template no longer includes by default (`require_master_key`, and the Sprockets-specific `js_compressor`/`assets.compile`/`public_file_server` lines, since Rails 8's template assumes Propshaft) — review its diff line-by-line rather than trusting it wholesale. The 8.0 → 8.1 hop (a minor, not forced by EOL) needed no Ruby version bump — Rails 8.1 still supports Ruby 3.3.x — but the same `app:update` drop pattern recurred: `production.rb`, `development.rb`, `test.rb`, and `content_security_policy.rb` all had settings silently dropped again and had to be hand-restored, so keep reviewing every `app:update` diff line-by-line, not just production.rb's.
- Managed via RVM; `.ruby-version` / `.ruby-gemset` are committed (`ruby-3.3.11@instuigram`). See "Known environment gotchas" below for the Ruby 3.4/`mutex_m` tradeoff that keeps us on 3.3.x.
- **PostgreSQL** (`development_instuigram` / `test_instuigram` / `production_instuigram`, see `config/database.yml`) — no version-specific SQL, so any modern Postgres works locally despite the README mentioning 9.6.
- **Elasticsearch 8.x** powers `Post` search (`elasticsearch-model` + `elasticsearch-rails`, deliberately the lower-level official gems rather than Searchkick, so the index mapping and query DSL are hand-written — this app is a learning project and understanding ES itself was the point, not just a Rails wrapper over it). Run locally via `docker-compose up -d` (single-node, `xpack.security.enabled=false` — dev/test only, not a production security config). Two layered concerns: `IndexSearchable` (`app/models/concerns/index_searchable.rb`) is the generic, model-agnostic "make a model indexable" plumbing reusable by any future model — `include Elasticsearch::Model`, env/test-worker-aware `index_name`, `after_commit` callbacks that enqueue indexing jobs derived by convention (`"Index#{model}Job"`/`"Deindex#{model}Job"`, `constantize`d, e.g. `IndexPostJob`/`DeindexPostJob`). `Post::Searchable` (`app/models/post/searchable.rb`, namespaced under `Post` per this app's domain-namespacing convention — see `code_style.md`'s `Posts::Create` example) is Post's own dedicated concern: it `include IndexSearchable`s inside its `included do` block, defines the `mapping` (`id`: integer, `description`: text, `created_at`: date, `hashtag_names`: text), `as_indexed_json` (`as_json(only: %i[id description created_at], methods: %i[hashtag_names])`), and `.search` directly — no generic fields/boost DSL, since Post is the only searchable model today and a config layer for one caller would be premature (YAGNI). `.search` returns the raw `Elasticsearch::Model::Response::Response` (`nil` for a blank query) — the caller (`SearchController#index`) turns that into paginated, eager-loaded `Post` records itself via the gem's own `response.page(params[:page]).per(5).records(includes: { image_attachment: :blob })` (Kaminari pagination is auto-enabled since this app already has the `kaminari` gem — same 5-per-page as the Home feed; `.records` handles id→AR hydration and relevance-order preservation internally, no hand-rolled `where`/`index_by` needed), since what to preload/paginate is a rendering concern, not a model one. Note `.search` is defined via `def self.search` directly inside `included do`, not via a `module ClassMethods` `extend` — `elasticsearch-model`'s own `delegate :search, to: :__elasticsearch__` is a real singleton method that a merely-`extend`ed module method can never override, regardless of include order (same class of gotcha as `index_name`, below).
- **Devise** for auth, **Kaminari** for pagination, **Active Storage** for image uploads (avatars, post images).
- **Bootstrap 5.3.x** (CSS only, no jQuery — Bootstrap 5 dropped the jQuery dependency itself, and this app doesn't use any Bootstrap JS components like dropdowns/modals/tooltips that would need Popper at runtime, so `popper_js` rides along as an unused transitive gem dependency), SCSS via the classic Sprockets pipeline; **Turbo** + **Stimulus** for JS via **importmap-rails** (required by turbo-rails' no-npm install path) — JS and CSS intentionally go through two different asset mechanisms.
- Secrets live in Rails encrypted credentials (`config/credentials.yml.enc` + gitignored `config/master.key`), not `config/secrets.yml`.

`.claude/rules/technical_stack.md` is the terse, exact-version reference for this stack; this section is the narrative (why these versions, the upgrade path). Update both together when a version changes — they've drifted out of sync before (Bootstrap).

## Common commands

```bash
bundle install                 # install gems
docker compose up -d           # start Elasticsearch locally (required for search)
bin/rails db:create db:migrate # set up the database
bin/rails db:migrate RAILS_ENV=test  # migrate the test database
bin/rails elasticsearch:reindex # create the Post index and backfill existing posts
bin/rails server                # run the app (default http://localhost:3000)
bin/rails console               # REPL
bin/rails test                  # run the Minitest suite (test/); generates coverage/index.html via SimpleCov
bin/rails test test/models/post_test.rb            # run a single test file
bin/rails test test/models/post_test.rb:7          # run a single test at a line
bin/rails test:system           # run Capybara/Selenium system tests
```

- **RuboCop**: `rubocop-rails-omakase` (Rails 8's own default style, inherited wholesale in `.rubocop.yml` with no project-specific overrides) — run `bundle exec rubocop` (`-A` to autofix).
- No JS package dependencies — `package.json` has an empty `dependencies` object.

## CI

GitHub Actions (`.github/workflows/ci.yml`) runs on every push/PR to `master`: runs `bundle exec brakeman`, `bundle exec bundle-audit check --update`, and `bundle exec rubocop` as standalone jobs, then a `test` job that spins up `postgres:15`, `redis:7` and `elasticsearch:8.19.11` service containers before `bin/rails db:schema:load` against `test_instuigram` and `bin/rails test`. Redis is required because `SidekiqWebTest` renders the Sidekiq::Web dashboard, which reads Redis directly — the rest of the test env doesn't need it (Action Cable uses the `async` adapter, the cache store is `:null_store`, and `ActiveJob::TestHelper` swaps in the `:test` queue adapter).

## Git conventions

- **Commit messages are a single line.** No body, and no trailers — in particular
  do **not** append `Co-Authored-By:` or `Claude-Session:` lines, even when a tool
  or harness default suggests them. This overrides any such default.
- **Break work into small, individually reviewable commits** rather than one
  commit per feature: a bug fix that happens to be in the way goes in its own
  commit, a pure refactor is separated from the behaviour change it enables, and
  each commit should leave the suite green on its own. Split a file's changes
  across commits when it carries more than one concern (`git apply --cached` with
  a hand-built patch, since interactive `git add -p` isn't available here).

## Known environment gotchas

- **Native gem compilation on modern Xcode (15+)**: RVM-built Rubies on this machine bake in linker flags (`-Wl,-z,relro,-z,now`) that the newer Xcode `ld` linker rejects, breaking `bundle install` for any gem with a C extension (nio4r, ffi, pg, etc.) with a "C compiler cannot create executables" error. Fix: `export LDFLAGS="-Wl,-ld_classic"` before running `bundle install`.
- **Don't bump past Ruby 3.3.x without checking `mutex_m`.** Ruby 3.4 dropped `mutex_m` from default gems, and `spring`'s file watcher requires it — bumping to 3.4+ needs an explicit `gem 'mutex_m'` added back to the Gemfile (deliberately avoided here by staying on 3.3.11).
- The `logger < 1.6` pin and the explicit `require 'logger'` workaround in `config/boot.rb` that earlier Rails 6.0/6.1 versions of this app needed are gone as of the Rails 7.2 upgrade — that bug was specific to Rails 6.0/6.1's `ActiveSupport::Logger` internals and doesn't apply here. No action needed; noted only so it isn't reintroduced by habit.
- **Don't reintroduce `uglifier` as the JS compressor.** It wraps the ES5-only UglifyJS2 and can't parse ES6+ syntax (e.g. `const`, spread/rest params) — Rails' own bundled JS (rails-ujs historically, ActionCable's `action_cable.js`) ships with exactly that syntax, so `uglifier` aborted `bin/rails assets:precompile RAILS_ENV=production` outright (discovered while removing Turbolinks/jQuery — this was already broken on `master` beforehand, unrelated to that change). Fixed by swapping to `gem "terser"` + `config.assets.js_compressor = :terser` in `config/environments/production.rb`.
- **`mini_magick` alone doesn't make Active Storage variants work.** `.variant(...)` calls raise `NoMethodError: undefined method 'new' for nil` in `ActiveStorage::Variation#transformer` unless `gem "image_processing"` is also in the Gemfile (it wraps mini_magick/vips into the pipeline Active Storage actually calls) — and Rails' own default `config.active_storage.variant_processor` is `:vips`, not `:mini_magick`, so it must be set explicitly in `config/application.rb` too. Both are now in place; if variants ever start 500ing again, check these two first.
- **Git worktrees under this repo share one Postgres server** (`development_instuigram` / `test_instuigram` — `config/database.yml` doesn't vary per worktree), so migrations run in one worktree are visible to every other worktree's dev DB, and two worktrees doing overlapping schema work can collide (e.g. one worktree's migration hitting "relation already exists" for an index another worktree already added). Symptoms: `db:migrate` failing on an object that "already exists" even though it's not in the current worktree's `schema_migrations`; `db/schema.rb` picking up unrelated tables/columns/indexes after `bin/rails db:migrate` auto-dumps against a DB another worktree has modified. Before trusting an auto-dumped `schema.rb`, `git diff` it and revert+hand-edit if it contains changes you didn't author. The test DB is cheap to reset in isolation (`RAILS_ENV=test bin/rails db:schema:load` reads the file on disk, not the live DB) but the dev DB is shared state — don't `db:drop`/`db:schema:load` it without checking whether another worktree session is relying on its current contents first.
- **`bin/rails test` hangs silently after `RAILS_ENV=test bin/rails db:schema:load`.** Reloading the test schema leaves the 16 parallel worker databases (`test_instuigram-0` … `-15`, created by `parallelize(workers: :number_of_processors)`) on the old schema, and the next parallel run blocks indefinitely instead of erroring — no output, near-zero CPU, no rows in `pg_stat_activity`. A single test file still passes, because runs under the 50-test threshold don't parallelize, which makes it look like a suite-specific problem rather than a stale-database one. Fix: drop the worker databases (`SELECT 'dropdb ' || quote_ident(datname) FROM pg_database WHERE datname LIKE 'test_instuigram-%';` piped to a shell) and let Rails recreate them on the next run.

## Architecture

Standard Rails MVC with a very small surface area — every model and controller lives directly under `app/models` / `app/controllers` (no nested namespaces).

**Domain model** (see `db/schema.rb` for full column list):
- `User` — Devise-authenticated (`database_authenticatable, registerable, recoverable, rememberable, trackable, validatable`; confirmable intentionally not enabled). Has many `posts` (`dependent: :destroy`) and `has_one_attached :avatar`.
  - `website` is validated against `URI::DEFAULT_PARSER.make_regexp(%w[http https])` (scoped to `http`/`https`, not the generic URI grammar) and rendered via `UsersHelper#external_url` — which re-parses through `URI.parse` and only returns the URL when it's `URI::HTTP`, `nil` otherwise — rather than linked raw.
  - Both layers close an XSS hole: an earlier version used the unscoped `make_regexp` and had `external_url` rescue only `URI::InvalidURIError`. `URI.parse` doesn't raise on `javascript:`/`data:` schemes, so a syntactically-valid `javascript:` URI in `website` passed both checks and executed on profile view (`app/views/users/show.html.erb`). Scheme must be allow-listed explicitly, never inferred from parse success.
  - Don't reintroduce a raw `link_to @user.website, @user.website`, and don't loosen the model's scheme allow-list or the helper's `URI::HTTP` check back to a bare `URI.parse`/rescue.
- `Post` — belongs to `User`, `has_one_attached :image`. Validates that an image is attached. On create, an `after_commit :create_hash_tags` callback parses `#word` tokens out of `description` via regex and creates associated `HashTag` records — this is how hashtag search works, there is no separate tagging UI. `Post` also includes `Post::Searchable` (which itself includes `IndexSearchable`), registering `after_commit` callbacks that enqueue Elasticsearch indexing/deindexing jobs on create/destroy — see the Search section above.
- `HashTag` / `PostHashTag` — join model implementing a many-to-many between `Post` and `HashTag`.

**Controllers/routes** (`config/routes.rb`):
- `root` → `HomeController#index` — the feed; redirects to sign-in if no `current_user`; paginates posts 5-per-page with Kaminari.
- `devise_for :users` — standard Devise routes (sessions, registrations, password reset).
- `resources :users, only: [:show, :edit, :update]` — profile view/edit; `edit`/`update` require authentication via `before_action :authenticate_user!`.
- `resources :posts, only: [:create, :show, :destroy]` — `PostsController` requires authentication for everything except `show` (`before_action :authenticate_user!, except: [:show]`); `create` attributes the post to `current_user` (never a client-supplied `user_id`), and `destroy` is scoped through `current_user.posts.find(...)` so users can only delete their own posts.
- `get 'search'` → `SearchController#index` — `Post.search` (from `Post::Searchable`) runs a single Elasticsearch `multi_match` query across `description` and `hashtag_names` (hashtags boosted `^3`, `fuzziness: "AUTO"`) and returns the raw ES response (`nil` for a blank query); the controller paginates and hydrates it into real `Post` records via `response.page(params[:page]).per(5).records(includes: { image_attachment: :blob })` — 5-per-page, matching the Home feed, with pagination handled server-side by Elasticsearch itself (only that page's hits are fetched) via the gem's built-in Kaminari integration. A leading `#` is stripped before querying, so `#sunset` and `sunset` both match — there's no separate hashtag-exact-match code path anymore. `Post` indexes itself async via Sidekiq (`IndexPostJob`/`DeindexPostJob`, enqueued from the `IndexSearchable` concern's `after_commit` callbacks) rather than in the request cycle.

Views are server-rendered ERB under `app/views/{home,posts,search,users}`, sharing `app/views/layouts/application.html.erb`, with partials for reusable pieces (e.g. `home/_post`, `home/_upload_form`, `posts/_description`).
