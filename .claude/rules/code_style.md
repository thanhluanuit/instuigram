---
paths:
  - "**/*.rb"
  - "**/*.erb"
  - "**/*.rake"
  - "app/**"
  - "lib/**"
  - "config/**"
  - "Gemfile"
  - "Rakefile"
---

# Code Style Guide (Ruby + Rails + Frontend)

RuboCop is wired up via `rubocop-rails-omakase` (see
[`technical_stack.md`](technical_stack.md)) — defer to `.rubocop.yml` and
`bundle exec rubocop` over this file wherever they overlap; the rules below
cover what the linter doesn't (naming conventions, architecture, N+1s, and
other things no cop checks). No ERB Lint yet. When in doubt, match the
surrounding file.

## Ruby

- **Two-space indent**, no tabs. Max line length ~100–120 (match the project's
  RuboCop config).
- Use `frozen_string_literal: true` magic comment on new files.
- Prefer `&&`/`||` over `and`/`or` (different precedence — `and`/`or` cause bugs).
- Guard clauses over nested conditionals:
  ```ruby
  return unless user.active?
  # happy path here
  ```
- Prefer `each`, `map`, `select`, `reduce` over manual loops. No mutation inside
  a `map`.
- Reach for the shape-specific Enumerable method before hand-rolling one:
  `filter_map` instead of `map` + `compact`, `each_with_object` instead of a
  mutated local, `tally` / `group_by` instead of a manual counting hash.
- Use keyword arguments for methods with more than one argument or any boolean.
- Small methods (aim < 10 lines); extract private methods freely. This is the
  mechanical heuristic — the single-responsibility rationale behind it lives in
  [`principles.md`](principles.md).
- Use `%i[]` / `%w[]` for symbol and word arrays.
- String interpolation over concatenation. Default to double quotes — Rails'
  own `rubocop-rails-omakase` config standardizes on them — but match the
  project's actual RuboCop config if it says otherwise.

## Rails

- **Naming**: models singular (`User`), tables plural (`users`), controllers
  plural (`UsersController`). Follow it exactly — Rails relies on it.
- **Query in the model, not the view or controller.** Expose named scopes:
  ```ruby
  scope :active, -> { where(archived_at: nil) }
  ```
- **Always guard against N+1**: use `includes`/`preload`/`eager_load`. See
  [`performance.md`](performance.md).
- **Strong parameters** in every controller — never `permit!`. See
  [`security.md`](security.md).
- **Enums** for status-like columns; back them with a DB default and a check
  constraint. Prefer a string-backed column (`enum :status, %w[pending active]`)
  over an integer-backed one — the value is readable in the DB and in logs, and
  reordering the definition can't silently reassign existing rows to the wrong
  state.
- **Callbacks sparingly** — they create hidden coupling and slow tests. Prefer
  explicit service calls for anything with side effects (emails, jobs, external
  APIs).
- **Service objects**: not in use yet — this app is small enough that
  `create`/`destroy` actions in controllers and callbacks on the model (e.g.
  `Post#create_hash_tags`) cover current needs, and there's no `app/services`
  directory. If a future addition needs one, give it one public entry point
  (`.call` / `#call`), namespaced by domain to match Zeitwerk's
  path-to-constant convention (`app/services/posts/create.rb` →
  `Posts::Create`). Keep the file path and constant name in exact
  correspondence — a mismatch fails autoloading, not compilation, so it
  surfaces as a confusing runtime error far from the cause.
- **Migrations**: one concern per migration, reversible, with the right indexes.
  Add `NOT NULL` and foreign keys at the DB level. For safe practice on a live
  database (concurrent indexes, backfills, FK validation), see
  [`performance.md`](performance.md).
- **Time**: always `Time.current` / `Date.current` (zone-aware), never
  `Time.now`.
- **Money**: integer cents or a dedicated type — never floats.
- **I18n**: user-facing strings go through `t(...)`, not hard-coded.

## Frontend (Hotwire / ERB / JS)

- **Prefer server-rendered HTML + Hotwire** (Turbo Frames/Streams, Stimulus)
  before reaching for a SPA framework.
- **Turbo Frame/Stream target ids**: use `dom_id(record)` /
  `dom_id(record, :prefix)` rather than hand-built strings — it keeps the id in
  one place and prevents drift between the tag that declares a frame and the
  broadcast that targets it.
- **No logic in ERB** beyond simple presentation. Extract to helpers or
  presenters (this app doesn't use ViewComponent — see
  [`technical_stack.md`](technical_stack.md) — reach for it only if the
  project adopts it deliberately). Never run queries in a view.
- **Escape by default** — never `raw`/`html_safe` on user-derived content
  without sanitizing first. See [`security.md`](security.md).
- **Stimulus controllers** are small and focused; name data attributes by intent
  (`data-controller`, `data-action`, `data-*-target`).
- **JavaScript**: no inline `<script>` handlers; use `const`/`let` (never `var`);
  keep DOM lookups scoped to the Stimulus controller's element.
- **CSS**: this project uses Bootstrap 4.6.x (CSS only, no jQuery) with SCSS
  via `sass-rails` — see [`technical_stack.md`](technical_stack.md). Prefer
  Bootstrap utility/component classes over custom rules; when you do need
  custom SCSS, scope it with BEM-style naming rather than deep nesting or
  global selectors. No inline styles for anything reusable.
- **Accessibility**: semantic elements, `alt` text, labels tied to inputs,
  keyboard-navigable interactions.

## Comments & docs

- Comment the *why*, not the *what*. Delete commented-out code — git remembers.
- A public method with non-obvious behavior gets a one-line doc comment.
- Match the file's existing comment density; don't over-annotate.
