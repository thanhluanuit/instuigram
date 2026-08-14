---
paths:
  - "**/*.rb"
  - "app/views/**"
  - "config/**"
---

# Performance Optimization

Measure before optimizing. Reach for these rules by default; profile before doing
anything exotic.

## Database is the first place to look

- **Kill N+1 queries.** Use `includes` / `preload` / `eager_load` for associations
  you'll render — including in serializers and `.jbuilder` templates, not just
  ERB. Add the [`bullet`](https://github.com/flyerhzm/bullet) gem in development
  to catch them.
- **Index what you query and join.** Every foreign key, every column in a `WHERE`,
  `ORDER BY`, or `JOIN`. Unique indexes back uniqueness validations. On Postgres,
  reach for a partial index (`where:`) when a query always filters to a slice of
  the table, and a covering index (`include:`) to enable index-only scans on hot
  read paths.
- **Select only what you need**: `select(:id, :name)`, `pluck` for single columns,
  `pick` for a single row. Don't instantiate full AR objects to read one field.
- **Batch large iterations** with `find_each` / `in_batches` — never load a huge
  table into memory with `.all.each`. Both ignore a custom `order`/`limit`; don't
  combine them with either and expect it to apply.
- **Avoid queries in loops.** Load the set once, then work in Ruby, or use a
  single aggregate query (`group`, `count`, `sum`).
- **Bulk writes**: `insert_all` / `upsert_all` / `update_all` / `delete_all` skip
  callbacks and validations but are an order of magnitude faster than
  instantiating and saving one record at a time — use them for genuine bulk
  operations, not as a shortcut around validations.
- **Use `exists?`** instead of `present?`/`any?` when you only need existence.
- **`counter_cache`** for association counts you display often — it counts every
  row regardless of scope, so a `default_scope` or soft-delete gem (Discard,
  Paranoia) will make it drift from what you actually display.

## Migrations on live databases

- Adding an index on a large table: use `algorithm: :concurrently` (and
  `disable_ddl_transaction!`).
- Adding a `NOT NULL` column: add nullable + backfill in batches + then enforce.
- Adding a foreign key on a large table: add it `validate: false`, then validate
  in a separate migration (`validate_foreign_key`) — a validating FK add takes a
  full-table lock until it finishes.
- Removing a column: ignore it first (`self.ignored_columns = [...]`, for at
  least one deploy) before dropping it — an app instance still running the old
  code will error on a column that vanished from under its schema cache.
- Never do heavy backfills inside a schema migration on a big table — use a
  separate data task or job.

## Caching

- **Fragment / Russian-doll caching** for expensive view partials, keyed on the
  record so it expires automatically.
- **`Rails.cache`** for expensive computed values; always set an expiry.
- **Use a shared cache store in production** (Solid Cache, Redis) — `:memory_store`
  is per-process, so under multiple Puma workers each process caches and misses
  independently, quietly undoing most of the win.
- **HTTP caching** (`fresh_when` / `stale?`) for cacheable controller actions.
- Cache the result, not the bug — never cache around a correctness problem.

## Background work

- Move anything slow or external (email, third-party APIs, image processing,
  bulk writes) into a background job.
- Jobs must be **idempotent** and take **IDs, not serialized objects**, as
  arguments.
- **Enqueuing in a loop is its own N+1.** Batch-enqueue where the adapter
  supports it (e.g. Sidekiq's `perform_bulk`) instead of calling `perform_later`
  per record.
- Set sensible retry/backoff; make failures visible in error tracking.

## Application & assets

- Avoid loading giant object graphs into memory; paginate list endpoints.
- Serialize APIs efficiently (`jbuilder` with care, or a fast serializer);
  don't render associations you don't return.
- Precompile and fingerprint assets; serve them via CDN in production.
- Set reasonable Puma worker/thread counts for the host; don't guess in prod.
  Match `config/database.yml`'s connection `pool` to the thread count — a pool
  smaller than max threads causes `ActiveRecord::ConnectionTimeoutError` under
  load.

## Before you optimize

1. Reproduce and **measure** — `pg_stat_statements` or `EXPLAIN (ANALYZE,
   BUFFERS)` for a query, `rack-mini-profiler`/APM for a request. Application
   logs reflect one replayed request at toy data volume, not production
   traffic — don't rank by them.
2. Fix the biggest cost first — usually the database.
3. Re-measure to confirm the win. Keep the benchmark in the PR description.
