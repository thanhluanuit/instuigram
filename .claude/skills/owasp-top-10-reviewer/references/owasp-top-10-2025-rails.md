# OWASP Top 10:2025 — Rails/Ruby Field Guide

The authoritative per-category detail for the review. Read this fully before reviewing.
Each category lists: **Rails manifestations** (what the flaw looks like in a Rails codebase),
**Where to look**, **Static signal** (Brakeman/bundler-audit checks that flag it, if any), and
**Remediation** (what a correct fix looks like). Severity is assigned per finding using the
rubric in SKILL.md, not fixed per category.

Anchored to OWASP Top 10:2025 (final, Jan 2026). SSRF is folded into A01. A03 (Supply Chain)
and A10 (Exceptional Conditions) are the 2025 additions/expansions.

---

## A01:2025 — Broken Access Control (incl. SSRF)

The most common and highest-priority class. Tools catch a fraction; most of this is
inspection of authorization logic.

**Rails manifestations**
- **Missing authorization**: a controller action that changes or reads a resource with no
  policy check (`authorize @record` / `can? :update, @record` absent). Authentication is not
  authorization — `before_action :authenticate_user!` alone does not gate per-object access.
- **IDOR / unscoped lookups**: `Model.find(params[:id])` where the record should be scoped to
  the current user/tenant. Correct: `current_user.invoices.find(params[:id])`.
- **Mass-assignment of authorization fields**: `params.permit(:role, :user_id, :account_id,
  :admin)` letting a user set ownership or privilege. Also `update_attribute(:role, ...)` from
  user input.
- **Skipped filters**: `skip_before_action :authenticate_user!` / `:verify_authorized` on
  actions that still touch protected data; `only:`/`except:` gaps.
- **Force-browsing / unprotected admin**: admin namespaces or Sidekiq/Flipper/PgHero mounts in
  `routes.rb` without a constraint or auth block.
- **Open redirect** (VERSION-GATED): `redirect_to params[:return_to]` / `redirect_to
  request.referer` without allow-listing. **This is default-blocked on Rails ≥ 7.0 new apps**
  (`raise_on_open_redirects`), so it is only a finding when: Rails < 7.0; an upgraded app that
  never enabled that framework default; or `allow_other_host: true` is passed with user input.
  Check the Rails version and framework-defaults state before flagging (the static script emits
  this) — otherwise it's a false positive on a modern stack.
- **SSRF (now A01)**: `Net::HTTP`, `open-uri` (`URI.open`), `HTTParty`, `Faraday`, `RestClient`,
  or image/PDF/webhook fetchers taking a user-controlled URL with no host allow-list. The trivial
  `URI.open(params[:url])` case is the easy one; the real risk hides behind **indirection** — a
  URL persisted then fetched later by a background job, a fetch that **follows redirects** (an
  allow-listed host 302s to `169.254.169.254`), or **DNS rebinding** (the allow-list check
  resolves a benign IP, the actual request resolves an internal one). A correct control
  **resolves the host, validates the IP against a deny-list of internal/link-local ranges, and
  pins that IP for the request** — not a regex on the hostname. Watch URL previews, avatar-by-URL,
  webhook callbacks, PDF/image processors.

**Where to look**: `app/controllers/**`, `app/policies/**` (Pundit) or `app/models/ability.rb`
(CanCanCan), `config/routes.rb`, any HTTP client call (including inside jobs), strong-params blocks.

**Static signal**: Brakeman warning types `Unscoped Find`, `Mass Assignment`, `Attribute
Restriction`, `Unsafe Redirects`, `File Access`, `Path Traversal`, `Cross-Site Request Forgery`.
SSRF and missing-policy-layer are NOT reliably tool-detectable — inspect.

**Remediation**: enforce a policy object per action; scope finds through the association chain;
allow-list redirect targets and outbound hosts; move admin mounts behind an authenticated
constraint.

---

## A02:2025 — Security Misconfiguration (up to #2)

Broad and high-yield in Rails because so much behavior is config-driven.

**Rails manifestations**
- `config.force_ssl = true` missing in production; HSTS not set.
- Permissive CORS: `rack-cors` with `origins '*'` combined with `credentials: true`.
- Verbose errors leaking to users: `config.consider_all_requests_local = true` or custom
  error pages that render exception messages/backtraces in production.
- Exposed diagnostic mounts: `/rails/info`, `mount Sidekiq::Web`, `PgHero`, `Flipper::UI`,
  `LetterOpener` without auth.
- Missing/weak security headers (CSP, X-Frame-Options, X-Content-Type-Options, Referrer-Policy).
- `config.filter_parameters` not covering `:password`, `:token`, `:secret`, `:ssn`, card data
  (this also feeds A09).
- Default/example credentials or seeds shipped to production; `secret_key_base` committed.
- Host authorization disabled (`config.hosts.clear`) enabling host-header injection.

**Where to look**: `config/environments/production.rb`, `config/initializers/*` (cors, csp,
filter_parameter_logging, session_store), `config/routes.rb` mounts, `config/credentials*`.

**Static signal**: Brakeman warning types `Default Routes`, `Information Disclosure`, `Session
Settings`. CORS, CSP/headers, and hardcoded secrets are **inspection-only** — Brakeman has no CORS
or header warning type. Header posture best confirmed with
securityheaders.com against a running instance.

**Remediation**: force SSL + HSTS; tighten CORS to explicit origins; disable detailed errors in
prod; auth-gate all mounts; complete `filter_parameters`; keep secrets in credentials/ENV.

---

## A03:2025 — Software Supply Chain Failures (NEW/expanded)

Expanded from 2021's "Vulnerable & Outdated Components" to the whole dependency, build, and
distribution chain. **bundler-audit is the primary signal here.**

**Rails manifestations**
- Gems in `Gemfile.lock` with known CVEs (bundler-audit / ruby-advisory-db).
- Unpinned or floating gem versions; `gem "x"` with no constraint on security-sensitive gems.
- Dependencies pulled from `git:`/`github:` refs (mutable, unsigned) or non-canonical sources.
- No automated dependency scanning (Dependabot / bundler-audit in CI) or lockfile not committed.
- Build/CI integrity gaps: unpinned GitHub Actions (`uses: foo/bar@main`), secrets exposed to
  third-party actions, no lockfile verification.

**Where to look**: `Gemfile`, `Gemfile.lock`, `.github/workflows/**`, `.github/dependabot.yml`,
`package.json`/`yarn.lock` if a JS build is present.

**Static signal**: **bundler-audit** (`bundle audit check --update`) — direct. Also flag missing
CI scanning by inspection.

**Remediation**: patch or replace vulnerable gems; pin versions; prefer rubygems.org sources;
add bundler-audit + Dependabot to CI; pin Actions to commit SHAs.

---

## A04:2025 — Cryptographic Failures

Root-cause framing of what used to surface as "sensitive data exposure."

**Rails manifestations**
- Weak or broken hashing for secrets: `Digest::MD5`/`Digest::SHA1` for passwords instead of
  `has_secure_password` (bcrypt). Note: `has_secure_password` uses **bcrypt**, not Argon2 — Argon2
  is a fine choice but requires the `argon2` gem, it is not a drop-in flag on `has_secure_password`.
- Homemade crypto or ECB mode; static/hardcoded IV or key; `OpenSSL::Cipher` used without a
  random IV per message.
- Predictable randomness for security tokens: `rand`/`SecureRandom` misuse — use
  `SecureRandom.hex`/`.urlsafe_base64` for tokens, never `rand`.
- Sensitive attributes stored in cleartext where they should use ActiveRecord `encrypts` (or
  Lockbox/attr_encrypted): PII, tokens, API keys.
- Secrets in source or logs; `config.filter_parameters` gap (cross-refs A02/A09).
- TLS: `OpenSSL::SSL::VERIFY_NONE`, disabled cert verification on outbound clients.

**Where to look**: models with `encrypts`/password logic, any `Digest::`, `OpenSSL::Cipher`,
`SecureRandom` vs `rand`, `verify_mode`, credential handling.

**Static signal**: Brakeman warning types `Weak Hash`, `SSL Verification Bypass`. Hardcoded
secrets are inspection-only (no stable Brakeman warning type). Much is inspection.

**Remediation**: `has_secure_password` (bcrypt) or the `argon2` gem for passwords; AES-GCM with random IV or
Rails `encrypts` for data; `SecureRandom` for tokens; enable TLS verification; move secrets out
of code.

---

## A05:2025 — Injection

Where Brakeman is strongest. Covers SQLi, XSS, command, and code injection.

**Rails manifestations**
- **SQLi**: string interpolation into queries — `where("name = '#{params[:q]}'")`,
  `find_by_sql("... #{...}")`, `order(params[:sort])`, `.where("id IN (#{ids})")`,
  `pluck(Arel.sql(user_input))`. Correct: parameterized `where("name = ?", q)` / hash conditions.
- **LIKE-wildcard injection** (subtle): even a *parameterized* LIKE — `where("name LIKE ?",
  "%#{q}%")` — is safe from SQLi but still lets `q` inject `%`/`_` wildcards (and `\`), which can
  turn a lookup into a full-table scan or bypass a prefix filter. Escape the term with
  `sanitize_sql_like(q)` before interpolating into the pattern. Don't ship the "parameterized ⇒
  done" fix without this.
- **XSS**: `raw`, `.html_safe`, `<%== %>`, `sanitize` with permissive config, `content_tag`
  with unescaped input, `render inline:` with user data, JSON interpolated into `<script>`.
- **Command injection**: `system`, backticks, `%x[]`, `exec`, `Open3.capture*`,
  `Kernel.spawn` with interpolated user input. Correct: pass args as an array, never a string.
- **Code/eval injection**: `eval`, `instance_eval`, `class_eval`, `send`/`public_send` with a
  param-derived method name, `constantize`/`Object.const_get`/`safe_constantize` on user input.
- **Format-validation anchor bypass** (Brakeman: *Format Validation*): `validates :x, format: {
  with: /^...$/ }` uses `^`/`$`, which match line boundaries, so an attacker can smuggle a newline
  (`good@x.com\nevil`) past the check. Use `\A` and `\z`. Impact ranges from data-integrity to
  auth/injection bypass depending on the field.
- **Deserialization/template injection**: `Marshal.load` and `YAML.unsafe_load` on untrusted data,
  ERB from user input, dynamic `render params[:template]`. **Note (version-gated):** plain
  `YAML.load` is `safe_load` by default on Psych 4 / Ruby ≥ 3.1 — it is NOT a finding on a modern
  stack; the dangerous calls are `YAML.unsafe_load` / `Psych.unsafe_load` / `Marshal.load`, or any
  `YAML.load` on Ruby < 3.1.
- **ReDoS**: user input compiled into a `Regexp`, or catastrophic-backtracking patterns matched
  against user input.

**Where to look**: models (scopes/queries), controllers, views (`app/views/**`), any shell-out,
serialization calls, dynamic dispatch.

**Static signal**: Brakeman warning types `SQL Injection`, `Cross Site Scripting` (+ Content Tag /
JSON variants), `Command Injection`, `Dangerous Evaluation`, `Dangerous Send`, `Dynamic Render
Paths`, `Remote Code Execution`, `Format Validation` — high precision here.

**Remediation**: parameterized queries / hash conditions + `sanitize_sql_like` for LIKE; escape by
default, avoid `raw`/`html_safe` on user data; array-form shell commands; allow-list any dynamic
dispatch; `\A…\z` anchors in format validations; never deserialize untrusted data with `Marshal`
or `unsafe_load`.

---

## A06:2025 — Insecure Design

Design-level; largely LLM-reasoning, not tool-detectable. Focus on missing controls a correct
design would have.

**Rails manifestations**
- No rate limiting / throttling on auth, password-reset, or expensive endpoints (no
  `rack-attack` or equivalent) → enables brute force, credential stuffing, enumeration.
- Business-logic trust of client input: price, quantity, discount, `total` taken from params
  instead of recomputed server-side; negative quantities; race conditions on balance/inventory.
- No account lockout / progressive delay; unlimited OTP attempts.
- Missing defense-in-depth: single check gating a sensitive operation; no idempotency on
  payments; mass operations with no bound.
- Sensitive flows lacking re-authentication (email/password change, fund transfer).

**Where to look**: authentication & password-reset flows, checkout/payment/order logic, any
place client-supplied money or quantity is trusted, presence of `rack-attack` config.

**Static signal**: none reliable. Reason about the flow and trust boundaries.

**Remediation**: add throttling + lockout; recompute trusted values server-side; enforce
idempotency and limits; require re-auth on sensitive actions; threat-model the flow.

---

## A07:2025 — Authentication Failures (renamed)

**Rails manifestations**
- Weak Devise/auth config: no password complexity, low bcrypt cost, sessions not reset on login
  (session fixation — call `reset_session` before establishing the new session).
- Timing-unsafe token/secret comparison: `token == params[:token]` instead of
  `ActiveSupport::SecurityUtils.secure_compare` / `fixed_length_secure_compare`.
- Predictable or non-expiring tokens: password-reset/confirmation/API tokens using `rand`, no
  expiry, single-use not enforced, tokens logged or sent in URLs that get logged.
- User enumeration: login and password-reset responses that differ for known vs unknown
  accounts ("no such email" vs generic message).
- No MFA option for privileged accounts; "remember me" tokens not rotated/invalidated on logout.
- Credential stuffing possible (cross-refs A06 rate limiting).

**Where to look**: `config/initializers/devise.rb`, sessions/registrations/passwords
controllers, any custom token compare or generation, password-reset flow.

**Static signal**: Brakeman warning types `Authentication`, `Basic Authentication` (partial).
Mostly inspection.

**Remediation**: `secure_compare` for tokens; `reset_session` on login; expiring single-use
tokens via `SecureRandom`; uniform auth responses; offer MFA; rotate remember-me on logout.

---

## A08:2025 — Software or Data Integrity Failures

Trust-boundary and integrity verification at a lower level than A03.

**Rails manifestations**
- Insecure deserialization of attacker-influenced data (`Marshal.load`, `YAML.unsafe_load`; plain
  `YAML.load` only on Ruby < 3.1 — see A05 note) — integrity
  angle; also A05.
- Cookie tampering: storing trust-bearing values in plain `cookies[...]` instead of
  `cookies.signed[...]` / `cookies.encrypted[...]`; `CookieStore` holding sensitive session data;
  weak/rotated `secret_key_base` handling.
- **Unverified webhooks**: Stripe/GitHub/Twilio/Shopify webhook controllers that act on the
  payload without verifying the HMAC signature (`Stripe::Webhook.construct_event`,
  `ActiveSupport::SecurityUtils.secure_compare` of computed vs sent signature).
- Auto-update / remote code load without integrity check; unsigned artifacts trusted by the app.
- CI/CD steps that consume unverified third-party output.

**Where to look**: cookie/session usage, `app/controllers/**webhooks**`, any signature
verification, deserialization calls.

**Static signal**: Brakeman warning types `Unsafe Deserialization`, `Remote Execution in
YAML.load`, `Session Manipulation`, `Session Settings`.

**Remediation**: signed/encrypted cookies; verify every inbound webhook signature before acting;
`YAML.safe_load`/avoid `Marshal` on untrusted data; verify artifact integrity.

---

## A09:2025 — Security Logging & Alerting Failures (renamed — "Alerting")

2025 emphasizes that logging without alerting is near-useless.

**Rails manifestations**
- Security-relevant events not logged: login success/failure, authorization denials, password
  changes, admin/privileged actions, MFA events.
- **Sensitive data written to logs**: incomplete `config.filter_parameters`; PII/tokens/card
  data in logs; full request bodies logged.
- No error tracking / alerting integration (Sentry, Honeybadger, Datadog) → incidents invisible.
- Logs not tamper-resistant or centralized; no retention.
- No alerting thresholds on auth failure spikes or anomalies.

**Where to look**: `config/initializers/filter_parameter_logging.rb` (and
`config.filter_parameters`), auth controllers (do they log?), presence of audit gems
(`audited`, `paper_trail`) for sensitive models, error-tracking initializer.

**Static signal**: minimal — inspect `filter_parameters` coverage; otherwise reason about what
is/isn't logged and alerted.

**Remediation**: log auth and access-control events with actor + outcome; complete
`filter_parameters`; wire an error tracker with alerting; audit-log sensitive model changes;
centralize and retain logs.

---

## A10:2025 — Mishandling of Exceptional Conditions (NEW)

New in 2025: improper error handling, logic errors, and **failing open**. Highly relevant to
Ruby's broad-rescue habits.

**Rails manifestations**
- **Failing open**: a `rescue` in an authorization/authentication/payment path that swallows the
  error and continues as if permitted (e.g., `rescue => e; return true` in a policy; auth check
  wrapped in `rescue nil`).
- Overly broad rescues hiding security failures: `rescue Exception`, `rescue => e; end`,
  `rescue nil`, `... rescue false` on security-relevant operations.
- Exception messages/backtraces leaked to users (cross-refs A02).
- Transactions not rolled back on partial failure; returning success on partial completion;
  state left inconsistent after an error.
- Unhandled concurrency / race conditions (TOCTOU) on balance, inventory, uniqueness — check for
  DB-level constraints and locking, not just app checks.
- `retry` loops without bounds; `ensure` blocks that mask failures.

**Where to look**: every `rescue`/`ensure`/`retry`, especially in auth, authorization, payment,
and state-mutating paths; transaction blocks; concurrency-sensitive operations.

**Static signal**: mostly inspection. Brakeman's `Divide By Zero` warning type is one concrete
unhandled-exception signal that maps here. Grep the single-line cues (`rescue nil`, `rescue
false`, `rescue Exception`) directly; the broad `rescue => e` + empty/permissive body is
multi-line, so use `rg -U` (ripgrep multiline) or review rescue blocks in security paths by hand —
a line-by-line grep will miss it.

**Remediation**: fail closed — on error in a security decision, deny; rescue specific exceptions
only; never swallow errors in security paths; wrap multi-step mutations in transactions with
rollback; enforce invariants with DB constraints + locking.

---

## Cross-cutting notes

- A finding often maps to more than one category (e.g., `Marshal.load` on user data is A05 and
  A08). Assign the **primary** category by root cause, and mention the secondary in the note.
- Do not report a Brakeman signal verbatim as a finding without confirming it in the code —
  Brakeman has false positives (especially `SQL` on interpolated-but-constant strings). Verify,
  then report with the file:line and a fix.
- Absence of a control (no policy layer, no rate limiting, no webhook verification) is a valid
  finding even though no tool emits it. These are often the highest-impact issues.
