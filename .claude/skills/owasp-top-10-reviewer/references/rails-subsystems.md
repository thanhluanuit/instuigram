# Rails Subsystem Coverage — beyond the controller/model/view core

The base field guide covers the classic request-cycle surface. These are the Rails subsystems that
a code-review pass CAN legitimately reach but Brakeman and a naive review routinely miss. Each maps
to an OWASP 2025 category; read this in Pass 2 alongside the core field guide. For a multi-tenant
SaaS (e.g. a recruitment platform with employer/candidate separation), **§1 Multi-tenancy is the
highest-priority section** — review it first.

---

## 1. Multi-tenant isolation  (A01 — often the #1 real risk)

Cross-tenant data exposure is the highest-impact bug class for a multi-tenant app and is almost
entirely invisible to static tools — it's a semantic property of every query.

**What to look for**
- **Unscoped finds across a tenant boundary**: `Model.find(params[:id])` / `Model.where(...)`
  that should be scoped to the current tenant (`current_account.jobs.find`, `current_employer.
  candidates`). An IDOR inside a tenant is bad; one *across* tenants is a breach.
- **Reliance on `default_scope` for tenancy**: `default_scope { where(account_id: Current.account) }`
  is bypassable (`unscoped`, `.unscoped.find`, associations, raw SQL, `reorder`) and gives false
  confidence. Tenancy should be enforced at the query/association layer, not a default_scope.
- **`Current` attributes leaking across requests**: `ActiveSupport::CurrentAttributes` not reset
  between requests (thread reuse) → one tenant's context bleeds into another. Confirm reset.
- **Cross-tenant cache/lookup keys**: caches, memoized class vars, or Redis keys not namespaced by
  tenant (see §6).
- **Global uniqueness / enumeration**: sequential IDs across tenants enabling enumeration; prefer
  scoped uniqueness and non-sequential public IDs.
- **Admin/impersonation**: "act as" / support-login features without audit trail or scope guard.

**Where to look**: every controller `before_action` that sets tenant context; models with
`account_id`/`employer_id`/`organization_id`; `Current`/`CurrentAttributes`; any `unscoped`; cache
key construction; background jobs (§3) that must re-establish tenant scope.

**Static signal**: none — pure inspection. Grep leads: `default_scope`, `\.unscoped`, `Current\.`,
`find\(params\[:id\]\)` in tenant-scoped models.

**Remediation**: scope every tenant-owned query through the tenant association; treat `default_scope`
as defense-in-depth, never the control; reset `CurrentAttributes` per request; namespace all caches
by tenant; audit impersonation.

---

## 2. ActiveStorage  (A01 SSRF / A05 / A08)

- **SSRF via remote attach**: `attach(io: URI.open(params[:url]))` or `url:`-based ingestion fetches
  a user URL server-side → SSRF (see core A01 SSRF: resolve-and-pin, block internal ranges).
- **Content-type spoofing**: trusting the client-supplied `content_type`; serving user uploads from
  the app origin with a type that renders as HTML/JS → stored XSS. Validate the *actual* type and
  serve from a separate origin / with `Content-Disposition: attachment`.
- **Image-processor CVEs**: variant processing shells out to ImageMagick/libvips — track processor
  CVEs (ImageTragick lineage) and restrict delegates/policy.xml.
- **Filename path traversal**: using the raw uploaded filename in a path.
- **Direct-upload authorization**: the `direct_uploads` blob-creation endpoint and the later
  attach step both need authorization; blob→record association can be swapped (attach someone
  else's blob) if not checked.
- **Signed-ID scope**: relying on ActiveStorage signed IDs as access control — they're
  tamper-evident, not authorization.

**Where to look**: models with `has_one_attached`/`has_many_attached`, `attach(`, `direct_uploads`,
variant/`processed` calls, controllers serving blobs.

---

## 3. ActiveJob / background jobs  (A08 / A01 SSRF / A06)

- **Argument deserialization**: passing whole objects/GlobalID or complex args that get deserialized
  by the queue adapter; untrusted data reaching a job that deserializes → integrity/RCE risk.
- **SSRF outside the request cycle**: jobs that fetch user-supplied URLs (webhooks, imports,
  link-preview) — same SSRF rules as A01, easy to miss because it's not in a controller.
- **Lost tenant/auth context**: a job re-queries without re-establishing tenant scope (§1) → acts
  across tenants; or runs with elevated implicit trust.
- **Unauthenticated enqueue / job flooding**: user actions that enqueue unbounded jobs (DoS, A06);
  jobs whose args come straight from params without validation.
- **Sidekiq Web / dashboards**: mounted without auth (also A02).

**Where to look**: `app/jobs/**`, `perform` signatures, any HTTP fetch inside a job, `Current`/scope
setup in jobs, `mount Sidekiq::Web`.

---

## 4. ActionMailer  (A05 / A01 SSRF / A09)

- **Header / CRLF injection**: user input in `to`/`from`/`subject`/`reply_to` enabling header
  injection or address spoofing.
- **SSRF / content injection**: user-controlled URLs or remote images pulled into mail; open
  content in templates.
- **PII in mail logs**: full mail bodies (reset tokens, PII) written to logs (cross-refs A09).
- **Link/token leakage**: password-reset or magic-link tokens in URLs that get logged or forwarded.

**Where to look**: `app/mailers/**`, mailer views, any user input in headers, log config.

---

## 5. ActionCable / WebSockets  (A01 / A02)

- **Missing channel authorization**: `Channel#subscribed` that streams for a record without checking
  the current user owns it → the canonical Cable IDOR (stream from `params` unchecked).
- **Connection identification**: `Connection#connect` not verifying the user (relying on an
  unauthenticated cookie), or not scoping `identified_by`.
- **Origin checks**: `config.action_cable.allowed_request_origins` too permissive / disabled.
- **Cross-tenant broadcast**: broadcasting to a stream name guessable by another tenant.

**Where to look**: `app/channels/**`, `connection.rb`, `subscribed`/`stream_for`, cable config.

---

## 6. Caching  (A01 / A08)

- **User/tenant-unkeyed fragment caches**: `cache @record` or Russian-doll fragments whose key omits
  the viewer's tenant/authorization state → one user served another's cached fragment.
- **Cache key collisions**: keys built from non-unique or attacker-influenceable values.
- **Marshal-based cache poisoning**: Rails cache serializes with Marshal by default; a writable
  cache store (shared/undertrusted Redis) becomes a deserialization sink.
- **Caching authenticated pages** at the HTTP/CDN layer (Cache-Control) leaking private data.

**Where to look**: `cache` calls in views, `Rails.cache` usage, cache_store config, CDN/page-cache
rules, `expires_in`/`Cache-Control` on authenticated responses.

---

## 7. Authentication & federation flows  (A07 / A01)

Beyond the core A07 items (enumeration, fixation, timing, token handling):
- **OAuth**: `redirect_uri` not strictly allow-listed (open-redirect → token theft); missing/unbound
  `state` (CSRF on the callback); missing PKCE for public clients; accepting tokens for the wrong
  `aud`/client.
- **SAML**: signature not verified, or verified on the wrong element (XML signature wrapping);
  assertion replay (no `NotOnOrAfter`/`InResponseTo` check); relevant to enterprise SSO for employer
  accounts.
- **Session lifecycle**: no absolute timeout, no idle timeout, session not invalidated server-side on
  logout/password-change; "remember me" tokens not rotated.
- **MFA**: absent for privileged/employer-admin accounts; MFA bypass on secondary flows
  (reset/OAuth) — the common real-world bypass.

**Where to look**: OmniAuth callbacks, `devise` + strategies, SAML/SSO integrations, session config,
logout and password-change paths.

---

## 8. API / Hotwire specifics  (A01 / A05)

- **CSRF in API mode**: `protect_from_forgery with: :null_session` or `skip_forgery_protection` on
  endpoints that still mutate via cookie auth → CSRF. Token/stateless auth is the fix, not disabling
  the check silently.
- **Nested-attributes mass assignment**: `accepts_nested_attributes_for` + permissive `permit` over
  JSON reaching association FKs / privilege fields.
- **Turbo Stream / broadcast leakage**: `broadcast_*_to` targeting a stream another user can
  subscribe to; rendering with the broadcaster's privileges, not the viewer's.
- **Over-broad serializers**: `to_json`/serializers exposing columns (password digests, internal
  flags, other-tenant fields) — mass *disclosure*, the read-side of mass assignment.
- **GraphQL** (if present): missing per-field authorization, introspection in prod, query-depth/
  complexity limits (DoS, A06).

**Where to look**: API controllers, `protect_from_forgery`/`skip_forgery_protection`,
`accepts_nested_attributes_for`, serializers/`as_json`, `broadcast`/Turbo, GraphQL schema.

---

## 9. Secrets in git history  (A02 / A04 — out of tree)

The skill scans the working tree; real leaks hide in **past commits** (a key committed then removed
is still in history and still valid until rotated). This is out of scope for a tree scan — flag it
and recommend a history scanner (`gitleaks detect`, `trufflehog git`) in CI, plus rotation of
anything found. Note it in coverage rather than pretending the tree scan covers it.

---

## Coverage honesty

This file extends what the *code-review pass* can reach. It still cannot see runtime behavior
(DAST), cloud/IAM/container posture, or git history (except to recommend the right tool). Those are
separate program layers — see the benchmark's interpretation notes.
