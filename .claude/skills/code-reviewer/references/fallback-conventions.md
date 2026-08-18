# Fallback Conventions

Used only when the target repo has **no** `.claude/rules/*.md` to read directly — a condensed,
framework-level baseline so the cleanup pass still has something real to cite instead of
inventing taste. If the target repo has its own rules, prefer those; they reflect real decisions
made for that codebase, this doesn't.

## Convention over configuration

Rails infers behavior from naming (`User` model → `users` table → `UsersController`). Code that
fights this — a table named against convention with manual `self.table_name=`, a controller that
doesn't map to its resource — trades predictability for nothing unless there's a stated reason.
Prefer built-in Rails idioms (validations, associations, scopes, ActiveJob, ActionMailer, Active
Storage) over hand-rolled versions of the same thing.

## DRY, but only after it's proven

Two similar-looking blocks are not automatically duplication — check whether they encode the
*same business rule* or just look alike syntactically. Don't flag a "should be extracted" cleanup
on the first occurrence; the threshold is roughly three occurrences of a genuinely identical
pattern. An abstraction built on a coincidental resemblance is more expensive to unwind later
than the duplication it removed.

## SOLID, in Rails terms

- **Single responsibility** — skinny controllers (authenticate, authorize, call one domain
  method, render — no business logic), models that don't become god objects (extract a concern,
  PORO, or service object when one grows past one responsibility).
- **Open/closed** — extend via Rails' own seams (concerns, STI, polymorphic associations,
  decorators), not monkey-patching the framework.
- **Liskov substitution** — STI subclasses and duck-typed collaborators should be swappable
  without the caller branching on `is_a?`/`class ==`; that branch is a sign the abstraction is
  wrong.
- **Interface segregation** — narrow, single-purpose concerns/modules, not one god-module mixed
  in everywhere.
- **Dependency inversion** — for real external boundaries (payment providers, third-party APIs),
  let the collaborator be passed in (a keyword arg with a sensible default is enough); don't
  hardcode `ExternalApi.new` deep inside a model. Skip this for Rails-internal collaborators
  (ActiveRecord, ActiveJob) — inverting those is needless ceremony.

## Style is enforced by tooling first

Don't raise a finding for anything RuboCop (with `rubocop-rails`, `rubocop-performance`) or ERB
Lint would already catch — indentation, quoting, line length, common Rails cops. Only raise a
style-adjacent point when it's a judgment call a linter can't make.

## Testing baseline

Tests should assert behavior, not implementation — a test that would still pass after the
production change is reverted isn't testing the change. Cover the failure/edge path a new branch
or validation introduces, not just the happy path. Keep test setup minimal and intention-revealing
(prefer factories/fixtures over ad-hoc object graphs) so a failure is easy to diagnose.
