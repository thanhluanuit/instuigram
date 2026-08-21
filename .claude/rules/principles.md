# Principles

The non-negotiable engineering values for every Rails project. When a specific
style rule and a principle conflict, the principle wins.

## Convention over Configuration

- Follow Rails' naming and directory conventions exactly — models singular
  (`User`), tables plural (`users`), controllers plural (`UsersController`).
  Rails infers behavior from these; breaking them trades predictability for
  nothing.
- Prefer built-in Rails idioms (validations, associations, scopes, ActiveJob,
  ActionMailer, Active Storage) over hand-rolled infrastructure. Reach for a
  gem or a custom abstraction only when Rails genuinely doesn't cover the case.
- If you must override a Rails default, explain why in the commit message or
  PR description — an unexplained override reads as an oversight to the next
  person who finds it, and this project doesn't use code comments to carry
  that context (see [`code_style.md`](code_style.md)).

## DRY — but not at the cost of the wrong abstraction

- DRY is about knowledge, not text. Two blocks that look similar but encode
  different business rules are not duplication — don't force them into one
  shared method just because they're syntactically close.
- Extract only after a pattern proves itself: duplicate twice before
  abstracting on the third occurrence. An abstraction built on the wrong
  generalization is more expensive to unwind than the duplication it avoided.
- Once duplication is proven, push it into the layer it belongs to: shared
  query logic into named scopes, shared view logic into helpers, partials, or
  ViewComponents, shared behavior into concerns, POROs, or service objects.

## SOLID — in Rails terms

Ruby is dynamically typed and duck-typed, and Rails favors pragmatic OOP over
enterprise design patterns — don't reach for interfaces, abstract classes, or
DI containers Ruby doesn't need. Applied here, SOLID means:

- **Single responsibility** — fat models, skinny controllers, but not obese
  models. Controllers orchestrate: authenticate, authorize, call one domain
  method, render — no business logic. When a model outgrows one
  responsibility, extract a concern, PORO, or service object rather than
  letting it become a god object.
- **Open/closed** — extend behavior through Rails' own seams (concerns,
  modules, delegation) instead of monkey-patching the framework or a gem to
  change its behavior.
- **Liskov substitution** — duck-typed collaborators must be swappable
  without the caller branching on `is_a?` or `class ==`. A caller that
  type-checks its collaborators is telling you the abstraction is wrong.
- **Interface segregation** — keep concerns and modules narrow and
  single-purpose rather than one god-module mixed into everything. Don't force
  a class to carry methods it doesn't need for the caller's use case.
- **Dependency inversion** — for anything crossing a real boundary (external
  APIs, payment providers, third-party services), let the collaborator be
  passed in; a keyword argument with a sensible default is usually enough.
  Don't hardcode `ExternalApi.new` deep inside a model. Skip this for
  Rails-internal collaborators (ActiveRecord, ActiveJob) — inverting those is
  needless ceremony.

## Security and correctness are not optional

Never trade a security control or a correctness guarantee for convenience —
see [`security.md`](security.md) for the specifics.
