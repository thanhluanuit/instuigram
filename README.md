## Build Instagram by Ruby on Rails

[![CI](https://github.com/thanhluanuit/instuigram/actions/workflows/ci.yml/badge.svg)](https://github.com/thanhluanuit/instuigram/actions/workflows/ci.yml)
[![Ruby](https://img.shields.io/badge/Ruby-3.3.11-CC342D?logo=ruby&logoColor=white)](.ruby-version)
[![Rails](https://img.shields.io/badge/Rails-8.1.3.1-CC0000?logo=rubyonrails&logoColor=white)](Gemfile.lock)

**Instuigram** is an Instagram clone built on Ruby on Rails, covering what a real Rails application needs beyond CRUD: authentication, background jobs, caching, full-text search, real-time direct messaging, a follow graph, and a CI pipeline that enforces security and style on every push.

## What you'll learn from this project

- Bootstrapping a Rails app and structuring it around MVC
- Active Record: migrations, validations, callbacks, associations, and the query interface
- Views: layouts, partials, and form helpers
- Controllers: actions and strong parameters
- Rails routing
- File uploads with Active Storage
- Authentication with Devise, pagination with Kaminari
- Background jobs with Sidekiq and caching with Redis
- Full-text search with Elasticsearch
- Real-time UI with Action Cable and Turbo Streams, no SPA framework
- Keeping a growing model tidy: concerns, service objects, and counter caches
- Standing up a token-authenticated JSON API alongside the session-based web app

## Tech Stack

**Back-end**
- Ruby 3.3.11 · Rails 8.1.3.1 (`config.load_defaults 8.1`)
- PostgreSQL — primary database
- Redis — Rails cache store, Sidekiq queue backend, and Action Cable pub/sub (`redis` gem 5.4; CI runs Redis 7)
- Sidekiq 8.1 — background job processing
- Elasticsearch 8.x — full-text search through `elasticsearch-model` / `elasticsearch-rails`, the low-level official gems rather than Searchkick, so the index mapping and query DSL are hand-written
- Puma 8 — application server
- Devise 5 (authentication) · Kaminari (pagination) · Active Storage (file uploads)
- `image_processing` + `mini_magick` — Active Storage named variants, shelling out to ImageMagick rather than libvips
- JWT 3.2 — token issuance for the `/api/v1` surface

**Real-time**
- Action Cable over Redis, with hand-written Stimulus controllers — `ConversationChannel`, `InboxChannel`, `PresenceChannel`, `PostChannel`
- Turbo Streams via declarative `turbo_stream_from` — follow buttons, follower counts, comments and reactions

**Front-end**
- Server-rendered ERB (no ViewComponent)
- Turbo 2 + Stimulus 1.3 via importmap-rails — no npm build step, `package.json` has zero dependencies
- Bootstrap 5.3 (CSS only, no jQuery) via sassc-rails/SCSS, with every colour, radius and shadow a token in `_tokens.scss`
- Self-hosted woff2 webfonts and Font Awesome 4 icons — the app's CSP is `style_src :self` / `font_src :self, :data`, which rules out Google Fonts
- Sprockets serves CSS, fonts and images; importmap-rails serves all JS

**Quality & security**
- Minitest — model, controller, service, channel, job and Capybara/Selenium system tests
- SimpleCov — coverage report generated on every local `bin/rails test`
- RuboCop (`rubocop-rails-omakase`) — style
- Brakeman 8 — static security analysis
- bundler-audit — dependency CVE scanning
- `bullet` — N+1 query detection in development and test
- `annotaterb` — schema annotations above each model, with CI failing on drift
- CI runs five independent, parallel GitHub Actions jobs on every push: `brakeman`, `bundler_audit`, `rubocop`, `test` and `system_test` (Rails' default test glob excludes `test/system`, so the browser suite needs its own job)

## Key features

### Direct messaging

One-to-one chat with live delivery. Start a thread from someone's profile or the inbox, send
a message, and it lands in the other person's browser immediately — their navbar unread
badge ticks up and the conversation floats to the top of their inbox even if they are on a
different page. A dot on each avatar shows who is online right now.

- **Threads are deduplicated by the database.** `Conversation.key_for` sorts the two user
  ids into a `participants_key` carrying a unique index, so
  [`Conversations::FindOrCreate`](app/services/conversations/find_or_create.rb) rescues
  `RecordNotUnique` and re-finds rather than ever creating a second thread for one pair.
- **One service owns the write.** [`Messages::Create`](app/services/messages/create.rb)
  saves the message, denormalises `last_message_id` / `last_message_at` onto the
  conversation, and adjusts unread counts — bumping every other participant with an atomic
  `update_all("unread_count = unread_count + 1")` and zeroing the sender's — inside a single
  transaction, and broadcasts only once it commits.
- **Two broadcasts, two audiences.** `ConversationChannel` pushes a rendered Turbo Stream to
  whoever has the thread open; `InboxChannel` pushes JSON (unread count, total unread,
  preview, sender) to each participant so the badge and inbox row update from anywhere.
- **Read state clears live.** Opening a thread marks it read server-side; while it stays
  open, `conversation_controller.js` POSTs to `conversations/reads` as each message arrives.
  That controller also dedupes on message DOM id, because the form response and the
  broadcast render the same partial.
- **Presence needs no extra table.** `PresenceChannel` touches `users.last_seen_at` on a
  `periodically` timer and broadcasts only on the offline→online transition;
  `HEARTBEAT_INTERVAL` is derived as `ONLINE_WINDOW / 2` so nobody flickers offline between
  pings.

Conversations are 1:1 by construction — no group threads, typing indicators, or attachments.

### Follow

Follow and unfollow from a profile, a post header in the feed, the people results in search,
or the "Suggested for you" rail. Follower and following counts and the button's own state
update without a reload — and in every tab you have open at once.

- **Counts are counter caches**, not `COUNT(*)` — `users.followers_count` and
  `users.following_count`, maintained by `Follow`'s two `counter_cache` declarations.
- **Duplicates and self-follows are impossible in the database**: a unique index on
  `[follower_id, followed_id]` and a `follows_no_self_follow` check constraint sit behind the
  model validations, so [`Follows::Create`](app/services/follows/create.rb) can rescue
  `RecordNotUnique` and stay idempotent under a double click.
- **Two broadcast streams.**
  [`Follows::BroadcastCounts`](app/services/follows/broadcast_counts.rb) replaces the count
  partials on both users' `:follows` streams. [`Follows::BroadcastButton`](app/services/follows/broadcast_button.rb)
  replaces *every* `[data-follow-user-id=…]` element on the actor's own `:follow_state`
  stream, which the layout subscribes to on every signed-in page — so one click flips the
  button everywhere you have the app open.
- **Discovery reads the graph.** `User.suggested_for` fills the suggestions rail by excluding
  people you already follow; `Post.discoverable_for` does the same for `/explore`, ranking
  what is left by `reactions_count + comments_count`.

The home feed is deliberately *not* follow-filtered — it stays a global reverse-chronological
feed, and follow state only decides whether a post header offers a Follow button. Following
someone sends them no notification; it writes an `EventLog` row.

### Everything else

- Feed with infinite scroll, and a post detail modal
- Comments and emoji reactions (like/love/haha/wow/sad/angry), both live over Turbo Streams
- Elasticsearch search across descriptions and hashtags — hashtags boosted `^3`, fuzziness
  `AUTO`, and a leading `#` stripped so `#sunset` and `sunset` match the same way
- Explore: posts from people you don't follow yet, ranked by engagement
- Hashtags parsed out of a post's description on create
- Active Storage uploads with named, partly preprocessed image variants
- `EventLog` audit trail, written asynchronously by a Sidekiq job
- Sidekiq Web dashboard at `/sidekiq`, gated behind `user.admin?`
- Token-authenticated JSON API at `/api/v1`

## Architecture

Standard Rails MVC. `User` and `Post` are each split into concerns under `app/models/user/`
and `app/models/post/` rather than growing into god objects, and multi-step writes live in
`app/services/` instead of controllers or model callbacks.

**Domain model** — Devise-authenticated, PostgreSQL-backed:
- `User` → has many `posts`, an avatar via Active Storage; behaviour split across `Followable`, `Conversable`, `Avatarable` and `Presenceable`
- `Post` → belongs to a user, one attached image, auto-extracted `#hashtag` associations, indexed into Elasticsearch on commit; behaviour split across `Imageable`, `HashTaggable` and `Searchable`
- `Comment` and `Reaction` (polymorphic, emoji-style: like/love/haha/wow/sad/angry) attach to posts
- `Follow` → the social graph, a self-join across `users` with a counter cache on each side
- `Conversation` / `ConversationParticipant` / `Message` → 1:1 direct messaging, with a per-participant unread count
- `HashTag` / `PostHashTag` → many-to-many tagging, populated from post descriptions
- `EventLog` → a lightweight audit trail of key domain events (post created/destroyed, profile updated, comment/reaction/follow created, message sent), written asynchronously

**Real-time** — four Action Cable channels, each authenticated from the Devise session:
`PostChannel` (reaction and comment counts), `ConversationChannel` (messages in an open
thread), `InboxChannel` (unread badges and inbox rows) and `PresenceChannel` (online status).
Follows, comments and reactions additionally broadcast declaratively through
`Turbo::StreamsChannel`, so the app runs both a hand-written and a declarative real-time path
on purpose.

**JSON API** (`/api/v1`) — a separate, token-authenticated surface alongside the session-based web app:
- `POST /api/v1/clients` — verifies an email and password, then issues machine credentials (`client_id` / `client_secret`, stored with `has_secure_password`)
- `POST /api/v1/oauth` — exchanges those credentials for a short-lived JWT (1h) via a client-credentials-style flow
- `Api::V1::PostsController` — exposes posts (index/show/create/destroy) to authenticated API clients, scoped to the token's own user
- Both unauthenticated endpoints are throttled with Rails 8's native `rate_limit`

## Getting Started

**Prerequisites** — Ruby 3.3.11 (managed with RVM; `.ruby-version` and `.ruby-gemset` are
committed), PostgreSQL, Redis, ImageMagick, and an Elasticsearch 8 node.

```bash
bundle install

# Services. docker-compose.yml defines Elasticsearch only —
# Postgres and Redis are expected on the host.
docker compose up -d                       # Elasticsearch on localhost:9200
brew services start postgresql@14 redis    # or however you prefer to run them

bin/rails db:create db:migrate
bin/rails db:seed                 # sample users and posts; prints the generated password
bin/rails elasticsearch:reindex   # create the Post index and backfill

bundle exec sidekiq               # second shell: search indexing and event logging
bin/rails server                  # http://localhost:3000
```

Redis is not optional in development — it backs the cache store, the Sidekiq queue and
Action Cable, so chat, presence and live counts all need it. Any Elasticsearch 8 node will
do; the app reads `ELASTICSEARCH_URL` (default `http://localhost:9200`), `REDIS_URL`
(Sidekiq and Action Cable, default DB 1) and `REDIS_CACHE_URL` (the cache store, default
DB 2, kept separate so cache keys can't collide with queue data).

Seeds are split so either half can run on its own — `bin/rails db:seed:users` and
`bin/rails db:seed:posts`. Sample avatars and post images live under `db/seeds/`.

Run the test suite with `bin/rails test`, and the browser tests with
`bin/rails test:system` (headless by default; `HEADED=1` opens a real Chrome window).

## Article Series

This project began life as a step-by-step Medium series walking through building it from scratch:

- [Build Instagram by Ruby on Rails (Part 1)](https://medium.com/luanotes/build-instagram-by-ruby-on-rails-part-1-fef7837ee399) — 👏 2K · 💬 11
- [Build Instagram by Ruby on Rails (Part 2)](https://medium.com/luanotes/build-instagram-by-ruby-on-rails-part-2-d70b44f5c7e6) — 👏 628 · 💬 9
- [Build Instagram by Ruby on Rails (Part 3)](https://medium.com/luanotes/build-instagram-by-ruby-on-rails-part-3-2cb65dca46d7) — 👏 578 · 💬 3

## Screenshots

### Homepage
![Home page](app/assets/images/home_page.png "Homepage")

### Direct Messaging
![Direct Messaging](app/assets/images/chat_conversation.png "Direct Messaging")

### Follow a Profile
![Follow a Profile](app/assets/images/follow_profile.png "Follow a Profile")

### User Profile Page
![User Profile Page](app/assets/images/user_profile.png "User Profile Page")

### Edit User Page
![Edit User Page](app/assets/images/edit_user_profile.png "Edit User Page")

### Search Page
![Search Page](app/assets/images/search_page.png "Search Page")
