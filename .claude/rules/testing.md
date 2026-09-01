---
paths:
  - "test/**"
  - "spec/**"
---

# Testing

This project uses Minitest (Rails' default) with fixtures — not FactoryBot
(see [`technical_stack.md`](technical_stack.md)). **RSpec exists for exactly
one purpose: driving rswag under `spec/requests/api/`**, which generates
`swagger/v1/swagger.yaml` and the `/api-docs` Swagger UI from executable
request specs — rswag's DSL has no Minitest equivalent. That exception does
not generalize: a new model, controller, helper, mailer or system test goes
in `test/` as Minitest, and `spec/` grows only when an API endpoint is added
or its contract changes. The two suites are complementary, not redundant —
the Minitest API tests in `test/controllers/api/v1/` remain the regression
safety net, while the specs assert the documented contract (status codes plus
JSON Schema validation of each response body). SimpleCov
measures coverage locally (`coverage/index.html`, generated on every
`bin/rails test` run), report-only — CI (`.github/workflows/ci.yml`) prints
the summary percentage to the `test` job's log but doesn't enforce a
threshold. A coverage number isn't the safety net, though — it can't tell you
whether an executed line was actually *asserted on*, so the suite's own
quality is still what's worth trusting; these rules capture the conventions
that keep it worth trusting, and match what `test/` already does.

## Coverage & intent

- Every change ships with a test that fails without it — a suite that only
  documents happy paths misses regressions before a user does.
- Test behavior, not implementation. Assert on the public interface (return
  value, state change, response, rendered markup) — not on private methods or
  instance variables. A test that breaks on refactor without a real behavior
  change is a maintenance cost, not a safety net.
- Don't write a test for framework behavior you didn't write — a bare
  `validates :email, presence: true` doesn't need its own test proving Rails'
  validation works. Test validations and callbacks that carry real conditional
  or custom logic (e.g. `Post#extract_name_hash_tags`'s regex parsing).

## Test types

- **Model tests** (`test/models`) for business logic: validations, callbacks,
  scopes, instance/class methods — see `post_test.rb`'s hashtag-extraction
  coverage for the pattern.
- **Controller tests** (`test/controllers`) subclass `ActionDispatch::IntegrationTest`
  (Rails' default since 5.0, not the legacy `ActionController::TestCase`) —
  despite the directory name, these already exercise real routing, params,
  redirects, authentication, and rendered views in one pass, the same value a
  "request spec" gives in RSpec. Assert on response status, redirects, DB
  state (`assert_difference`), and `assert_select` for markup — not on
  instance variables.
- **API contract specs** (`spec/requests/api/v1`, RSpec + rswag) describe each
  endpoint in rswag's `path`/`response` DSL. They are documentation and test
  at once: `run_test!` issues the real request, asserts the declared status,
  and validates the body against the `schema` — so a response that drifts from
  the published contract fails the build. Declare shared shapes once in
  `spec/swagger_helper.rb` under `components.schemas` and `$ref` them; don't
  inline a response body shape in a spec. Bearer auth comes from
  `security [bearer_auth: []]` plus a `let(:Authorization)` — that exact
  constant-looking name is required, since rswag hardcodes `Authorization` as
  the header for any non-`apiKey` scheme. Build records inline (plain
  `ActiveRecord`, no fixtures and no FactoryBot); the shared `test_instuigram`
  database still holds the Minitest fixture rows, so scope every assertion to
  the records the spec created rather than to a global `Model.count`.
- **System tests** (`test/system`, Capybara + Selenium already in the Gemfile)
  are not feature-complete coverage and never will be — the faster layers
  above do the heavy lifting. A system test earns its place only when the
  behavior is **browser-only** — a Stimulus controller, a Turbo Frame or
  Stream applied client-side, an Action Cable broadcast reaching the DOM, or a
  native browser interaction (`data-turbo-method`, `turbo_confirm`, a file
  input, a keypress) — **and cannot be asserted at the controller layer**. If
  `assert_select` on a rendered response or on a `turbo-stream` tag would
  prove the same thing, write the controller test instead. The criterion is
  behavior-shaped, not count-shaped, so there's no per-file cap — but each
  file stays focused on one browser-only concern (`composer_test.rb`,
  `post_modal_test.rb`, `reactions_test.rb`, `inbox_test.rb`), and every
  system test must be justifiable by naming the browser-only behavior it
  exists for.
- Judge this layer by which browser-only behaviors are covered, not by
  SimpleCov — it measures no JavaScript at all, so `app/javascript` is
  invisible to the coverage number no matter how many system tests you add.
- Drive a multi-user realtime flow with a second Capybara session
  (`within_session_as`), and **always wait for the receiving browser's
  subscription to be confirmed** (`wait_for_cable`) before the other session
  acts — an unconfirmed subscription silently drops the broadcast and no
  amount of Capybara waiting will recover it. Broadcasts do reach a real
  browser even though `test_helper.rb` mixes in `ActionCable::TestHelper`
  (which swaps `ActionCable.server.pubsub` for the Test adapter) — that
  adapter subclasses `Async` and calls `super` in `broadcast`, so it records
  *and* delivers.
- System tests run in their own CI job (`bin/rails test:system`, headless
  Chrome). Rails' default test glob excludes `test/system`, so a green `test`
  job says nothing about them — and unlike controller tests, a real browser
  fetches Active Storage variants, so the job needs ImageMagick installed.
- Security-relevant paths need explicit non-owner coverage, not just the happy
  path — see [`security.md`](security.md)'s authorization-testing note.
  `posts_controller_test.rb` already does this (signing in as a different user
  and asserting `assert_response :not_found`); match that pattern for any new
  owner-scoped action.
- For any change touching queries, lock in an N+1 fix with Rails' built-in
  `assert_queries_count` / `assert_no_queries` (available since Rails 7.1, no
  extra gem needed) — see [`performance.md`](performance.md).

## Data & isolation

- **Fixtures, not factories.** `test/fixtures/*.yml` are loaded once per test
  via `fixtures :all` in `test_helper.rb`. Keep fixtures minimal and
  representative; when a test needs a specific variant, build it inline with a
  private helper method (see `build_post` in `post_test.rb`) instead of adding
  a new fixture row for every case.
- Add reusable test setup (e.g. attaching a test image) to a helper module
  mixed into `ActiveSupport::TestCase` in `test_helper.rb`, following
  `ActiveStorageTestHelper#attach_test_image` — don't reimplement the same
  setup inline across multiple test files.
- Each test must be independent: `parallelize(workers: :number_of_processors)`
  is already on, and each worker gets its own DB — don't add state that
  depends on execution order or on another test's side effects.
- Never call a real third-party API in a test. None exist today; if one gets
  added later, stub outbound HTTP (e.g. WebMock) rather than hitting it for
  real.
- Freeze or travel time (`freeze_time` / `travel_to`) for anything
  time-sensitive instead of stubbing `Time.now`/`Date.today` directly —
  matches the zone-aware `Time.current` convention in
  [`code_style.md`](code_style.md).

## Structure & maintenance

- One behavior per test, named as a full sentence describing scenario and
  outcome (`"when signed in as a different user, hides the Remove link"`) —
  the existing suite is consistent about this; match it rather than
  introducing terser names.
- Use `setup do ... end` for shared arrangement (see `PostTest`'s
  `@user = users(:one)`) and private helper methods for object construction.
  Only reach for a shared module once the same construction is genuinely
  duplicated across multiple test files — the "duplicate twice before
  abstracting" rule from [`principles.md`](principles.md) applies here too.
- A flaky test is a bug, not noise — fix it or explicitly skip it with a
  tracked reason, never leave it randomly red.

## Speed

- Model and controller tests should dominate the suite by count. A system test
  is added only under the browser-only rule above — that rule, not a quota, is
  what keeps this layer small.
- Parallel execution is already on (`parallelize`) — no action needed until
  the suite is slow enough to warrant tuning worker count further.
