---
paths:
  - "test/**"
---

# Testing

This project uses Minitest (Rails' default) with fixtures — not RSpec, not
FactoryBot (see [`technical_stack.md`](technical_stack.md)). There's no
coverage tool, and CI (`.github/workflows/ci.yml`) only runs the suite as-is
without measuring coverage, so the suite itself is the only safety net;
these rules capture the conventions that keep it worth trusting, and match
what `test/` already does.

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
- **System tests** (`test/system`, Capybara + Selenium already in the Gemfile)
  cover a deliberately small set of critical end-to-end flows —
  `posts_test.rb` (sign in → create a post → see it in the feed; delete your
  own post) and `search_test.rb` (hashtag search) — not feature-complete
  coverage. Keep additions to one or two critical flows per file; they're the
  slowest and most flake-prone layer, and the faster layers above should do
  the heavy lifting.
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

- Model and controller tests should dominate the suite by count; system tests
  stay the minority, reserved for flows that genuinely need a real browser.
- Parallel execution is already on (`parallelize`) — no action needed until
  the suite is slow enough to warrant tuning worker count further.
