# Rails Correctness Pitfalls

Patterns where Rails' conventions make it easy to write code that *looks* right and passes a
casual read, but is wrong on a real input. Each entry: what it looks like, why it's wrong, the
fix. Use these as detection leads during the correctness pass — confirm each in the actual diff
before reporting; a pattern match is not yet a finding.

## Callback and transaction ordering

- **`after_save` callback that reads what `before_save` was supposed to have set.** If a
  `before_save` callback assigns an attribute another `after_save` callback depends on, and a
  validation or earlier callback can halt the chain, the second callback may run against stale
  state. Trace the actual callback order (`ActiveSupport::Callbacks` runs them in definition
  order per type) rather than assuming.
- **Work with external side effects (emails, API calls, job enqueues) inside a
  `transaction do...end` block.** If the transaction rolls back after the side effect already
  fired (e.g., an exception two lines later), the email/API call already happened but the DB
  state didn't persist — a real, hard-to-reproduce bug. Move side effects to `after_commit`, or
  restructure so the side effect happens after the transaction closes.
- **`dependent: :destroy` vs `dependent: :delete_all` swapped**, or missing entirely, on an
  association whose destruction should cascade callbacks (e.g. cleaning up attached files,
  notifying a related record). `delete_all` skips callbacks and validations — correct for
  pure cleanup, wrong if the association's own `before_destroy` does real work.

## Validation vs. database constraint mismatches

- **A `validates :uniqueness` with no matching unique index.** Rails validations run
  application-side and race under concurrent requests — two requests can both pass validation
  before either inserts. If there's no DB-level `unique index` backing it, flag the gap: either
  add the index + a `rescue ActiveRecord::RecordNotUnique` path, or note the race explicitly.
  (This is a correctness/data-integrity issue, not a security one — still in this skill's lane.)
- **`validates :presence` on a column that's `null: false` with no default**, where a callback
  sets the value *after* validation runs (e.g. in `before_save` when the validation runs in
  `before_validation` or earlier) — looks safe, isn't, because the validation checks before the
  callback fills it in.

## Numeric and time correctness

- **`Float` for money or any value compared for equality.** Floating-point arithmetic on prices,
  balances, or percentages accumulates rounding error; use `BigDecimal` (a `decimal` column with
  Rails default mapping) and never `==` compare floats.
- **`Time.now` / `Date.today` instead of `Time.zone.now` / `Time.current` / `Date.current`.**
  Bypasses the app's configured time zone — correct in a server running in the same zone as
  `Time.zone`, silently wrong (off by the zone offset) anywhere else, including CI and most
  production hosts set to UTC.
- **`rand` or `SecureRandom` used where determinism is expected in a test or a replay-sensitive
  path** — not a security issue by itself, but produces flaky specs or non-reproducible bugs.

## Memoization and dirty-tracking bugs

- **`@foo ||= compute_foo` where `compute_foo` can legitimately return `false` or `nil`.** The
  memoization re-runs every time because `||=` treats falsy as "not yet memoized" — usually just
  wasteful, but a correctness bug if `compute_foo` has side effects (e.g. increments a counter,
  enqueues a job) that then fire more than once.
- **Checking `attribute_changed?` or `saved_changes` in the wrong callback phase.** After `save`
  completes, `changed?` methods report differently than during `before_save` — code copied from
  one callback into another silently checks the wrong state.

## Enums, STI, and type coercion

- **Rails `enum` backed by an integer column, with a value inserted/removed from the middle of
  the mapping.** Existing rows silently reinterpret to a different enum value — this is a data
  migration correctness bug, not just a style issue; flag any enum definition edit that isn't
  purely appending at the end.
- **STI subclass logic that branches on `is_a?`/`class ==`** instead of relying on the
  polymorphic behavior the base class defines — a Liskov violation that's also a correctness
  risk: a new subclass added later silently falls through every such branch's `else`.

## Background jobs

- **A job whose `perform` isn't safe to run twice**, enqueued somewhere retries are enabled
  (Rails' default job retry behavior, or Sidekiq's). If the job charges a card, sends an email,
  or increments a counter without an idempotency check, an automatic retry after a transient
  failure duplicates the side effect. Flag any job with an external side effect that lacks a
  guard (idempotency key, `find_or_create_by`, a "already processed" check).
- **Passing an ActiveRecord object into a job's `perform_later` args (instead of an id).**
  GlobalID serializes it, but if the record is deleted before the job runs, the job raises
  `ActiveJob::DeserializationError` — usually the intent was to look it up by id and handle the
  not-found case explicitly.

## Test correctness (when the diff touches specs)

- **`let` where `let!` was needed, or vice versa.** `let` is lazy — a test that depends on a
  record existing *before* an action runs (e.g. counting existing records) but only references
  it via `let` may pass by accident (if something else creates the record) or fail confusingly.
- **A stub/mock that hides the exact behavior the test claims to verify** — e.g. stubbing the
  method under test itself, or stubbing so broadly that the assertion would pass even if the
  real implementation were deleted. Ask: "if I revert the production change, does this test
  fail?" If not, it isn't testing the change.
- **Only the happy path is asserted** for logic with an obvious failure mode the diff introduces
  (a new validation, a new branch, a new external call) — flag the missing negative-path test as
  a correctness gap in coverage, per `testing.md`'s intent-over-coverage-percentage framing.
