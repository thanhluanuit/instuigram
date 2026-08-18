# Rails Performance Anti-Patterns — Detection Ruleset

Each entry: **how to find it**, **why it's slow**, **the fix**, **severity signal**, **how to verify**.
Detections list ripgrep patterns as a starting point — always confirm by reading the code; a
pattern match is a candidate, not a finding.

## Contents
1. Database queries (N+1, includes/joins, count/exists, map/pluck, subqueries)
2. Indexing
3. Caching
4. Background jobs
5. Memory
6. Views & serialization
7. Pagination
8. Pre-computation & memoization
9. Front-end (lightweight)

---

## 1. Database queries

### 1.1 N+1 queries (the highest-frequency Rails perf bug)
**Find:** an association accessed inside a loop or collection view without eager loading.
```
rg -n "\.each\b" app/views app/models app/controllers        # loops that may touch associations
rg -n "render @?\w+" app/views                                 # collection renders → check the controller query
```
Also enable `bullet` (dev) and `strict_loading` on hot models to catch these at runtime.
**Caveat:** plain `strict_loading` also raises on legitimately-lazy singular loads; prefer
`strict_loading: :n_plus_one_only` (or `mode: :n_plus_one_only`) so it flags collection N+1s
without breaking every lazy `belongs_to`.
**Why:** one query for the parent set, then one more per row for the association → 1+N queries.
On a 25-row listing that's 26+ queries where 2 would do.
**Fix:** eager-load. Choose deliberately:
- `includes` — Rails picks preload or eager_load; default choice.
- `preload` — always separate queries (good when you don't filter on the association).
- `eager_load` — single LEFT JOIN (needed when you filter/order by the association's columns).
**Severity:** Critical/High on list endpoints; Low on single-record or admin pages.
**Verify:** query count drops (`assert_queries(n)` in a request spec, or Bullet silent); in
production, the association's query shape shows a large drop in `calls` in `pg_stat_statements`.

### 1.2 `includes` used only to filter → use `joins`
**Find:** `rg -n "\.includes\([^)]*\)\.where\(" app` where the included data is never rendered.
**Why:** `includes` loads and instantiates all the association's rows into memory just to filter.
**Fix:** `joins` filters in SQL without loading the association. Use `includes` only when you
actually render the associated records.
**Severity:** Medium–High depending on association size. **Verify:** allocation/memory drop; fewer/lighter rows returned.

### 1.3 `.count > 0` / `.length == 0` → `.exists?`
**Find:** `rg -n "\.count\s*[><=]" app` and `rg -n "\.length\s*==\s*0" app`.
**Why:** `.count` runs `SELECT COUNT(*)` over the whole match; `.length` loads every record
into memory. Both to answer a yes/no. **Fix:** `.exists?` stops at the first row.
**Severity:** Medium (High on large tables in hot paths). **Verify:** EXPLAIN shows a LIMIT-1 style plan; faster query.

### 1.4 `.map(&:attr)` → `.pluck`; `.pluck(:id)` into `where` → subquery with `.select`
**Find:** `rg -n "\.map\(&:" app` and `rg -n "\.pluck\(:\w+\)" app` (watch for pluck feeding a `where`).
**Why:** `.map(&:x)` instantiates full ActiveRecord objects (all columns) to read one attribute.
`pluck(:id)` into `where(id: ...)` loads a big array of IDs into Ruby and ships it back to PG.
**Fix:** `.pluck(:x)` fetches only that column. To feed another query, use `.select(:id)` so PG
runs it as one subquery — no round-trip of IDs.
**Severity:** Medium–High by result size. **Verify:** one query instead of two; lower memory/bandwidth.

### 1.5 Redundant / unbounded queries
**Find:** same query issued repeatedly in a request; queries with no `limit`; `Model.all` in code paths.
**Why:** repeated identical queries should be memoized; unbounded result sets blow up memory and time.
**Fix:** memoize within the request (§8), add `limit`, or paginate. **Verify:** query count; response time.

---

## 2. Indexing

**Find:** cross-reference query filters/sorts against the schema file. **Check which
format the repo uses first** — the two spell indexes differently, and running the wrong
command returns zero hits, which reads as "nothing is indexed" and produces a batch of
bogus Critical findings.
```
rg -n "where\(|order\(|find_by" app | grep -oE "\b\w+_id\b|\b(status|state|slug|email|created_at)\b"

ls db/schema.rb db/structure.sql                               # which format? check, don't assume
rg -n "add_index" db/schema.rb                                 # Ruby DSL schema
rg -n "^CREATE (UNIQUE )?INDEX" db/structure.sql               # SQL structure dump
```
If the count comes back 0, suspect the command before the schema — confirm with
`rg -c "INDEX|add_index" db/*.sql db/*.rb`. Multi-database apps have more than one dump
(e.g. a separate tracking/analytics schema); check the one that owns the table.
Then confirm with `EXPLAIN (ANALYZE, BUFFERS)` on the real query.

### 2.1 Foreign keys and frequent filters without an index
**Why:** `WHERE status = 'active'` or a FK join without an index → **Seq Scan** on the whole
table; fine at 1k rows, 5 seconds at 1M. **Fix:** `add_index :products, :status`.
**Severity:** Critical if the column is filtered on a hot path over a large table.
**Caveat — how you add it matters as much as adding it:** a plain `add_index` takes an
ACCESS EXCLUSIVE lock and **blocks every write to the table** while PG builds it — on a large
production table that is an outage. Recommend `add_index :products, :status, algorithm: :concurrently`
with `disable_ddl_transaction!` in the migration. Concurrent builds are slower, need two table
scans, and can leave an **INVALID** index if they fail (drop it and retry — check with
`\d products` or `pg_index.indisvalid`). The `strong_migrations` gem enforces this in CI.

### 2.2 Multi-column queries without a composite index (and wrong column order)
**Why:** `where(status:).where(featured:).order(created_at:)` can use only one single-column
index; PG still sorts/filters the rest. **Fix:** `add_index :products, [:status, :featured, :created_at]`.
**Column order matters:** put equality-filter columns first, then the range/`ORDER BY` column last.
An index on `[created_at, status]` won't serve `WHERE status = ? ORDER BY created_at` well.
**Verify:** EXPLAIN switches Seq Scan → Index Scan / Index Only Scan; sort node disappears.

### 2.3 Over-indexing / unused indexes
**Why:** every index adds write cost and bloat. Indexes never used by any query are pure overhead.
**Fix:** check `pg_stat_user_indexes` for `idx_scan = 0` and drop dead indexes.
**Severity:** Low–Medium (write-heavy tables). **Verify:** write latency; index count.

> Reading a plan (quick reference): **Seq Scan** on a big table → likely missing index;
> **estimated rows ≫ actual** → stale stats, run `ANALYZE`; **index exists but unused** → wrong
> column order, type mismatch, or low selectivity. Full guidance in `diagnosis-playbook.md`.

---

## 3. Caching

### 3.1 Expensive query/render on every request, uncached
**Find:** heavy scopes (`order`, aggregates, joins) called in controllers/views with no cache;
`rg -n "Rails.cache.fetch" app` to see what IS cached. **Fix:** `Rails.cache.fetch(key, expires_in:) { ... }`
for data; fragment `cache [...] do` for view chunks. **Severity:** High on hot, stable data.
**Verify:** the query's `calls` and `total_exec_time` drop in `pg_stat_statements`; cache hit
ratio rises.

### 3.2 Missing fragment caching on collection views
**Find:** `render @collection` of stable content with no surrounding `cache` block.
**Fix:** Russian-doll caching — `cache [collection, collection.maximum(:updated_at)]` around the list,
`cache item` around each partial. **Verify:** view render time in `rack-mini-profiler` for the
action, before and after — view cost is Ruby, not SQL, so it won't appear in pg_stat_statements.

### 3.3 Cache without expiry or invalidation (stale data)
**Find:** `Rails.cache.fetch` with no `expires_in`; fragment keys that don't include `updated_at`.
**Fix:** include `updated_at` in the key and set `touch: true` on associations so a child update
bumps the parent's cache key. **Severity:** correctness + perf. **Verify:** edit data, confirm cache refreshes.

### 3.4 Cache stampede risk on hot keys
**Find:** a very hot `fetch` key with a fixed TTL and no stampede guard.
**Why:** when the key expires, every concurrent request recomputes it at once and hammers the DB.
**Fix:** `race_condition_ttl:` on `fetch`, or pre-warm. **Note:** `race_condition_ttl` does not
*lock* — on expiry it briefly serves the stale value to other callers while one recomputes, which
caps the stampede but isn't mutual exclusion. For strict single-flight, use an explicit lock
(e.g. a Redis lock) around the recompute. **Severity:** High for very hot keys.
**Verify:** no DB spike at expiry under load.

---

## 4. Background jobs

### 4.1 Synchronous work in the request path
**Find:**
```
rg -n "deliver_now" app                                        # mail sent inline
rg -n "Net::HTTP|Faraday|HTTParty|RestClient|Typhoeus" app/controllers app/models
rg -n "\.process|ImageProcessing|MiniMagick|Prawn" app/controllers
```
**Why:** email, external API calls, PDF/image processing block the response — the user waits
on work that doesn't need to be synchronous. **Fix:** move to a job (`deliver_later`,
`SomeJob.perform_later`). **Severity:** High (adds seconds to a user-facing request).
**Verify:** controller response time drops; External segment leaves the web transaction.

### 4.2 One huge job (timeout / retry risk)
**Find:** a job doing `Model.find_each { ... }` over an entire large table in a single run.
**Fix:** split into batched jobs (enqueue N jobs each handling a slice). **Severity:** Medium–High.
**Verify:** per-job runtime bounded; no timeouts.

### 4.3 Non-idempotent jobs
**Why:** jobs run at-least-once and are retried; a job that isn't safe to run twice corrupts data
or double-sends under retry. **Fix:** guard on state or a unique key. **Severity:** correctness (flag it).

---

## 5. Memory

### 5.1 Loading large collections into memory
**Find:** `rg -n "\.all\.each|\.each do" app` on model relations without batching; building big arrays.
**Why:** `User.all.each` loads every row (and full objects) into RAM at once → GC pressure, RSS spikes.
**Fix:** `find_each` / `find_in_batches` (batches of 1000 by default). For bulk writes prefer
`update_all` / `delete_all` over per-record iteration. **Severity:** High on large tables.
**Caveat:** `find_each` **overrides any `ORDER BY`** (it forces primary-key order to batch) and
**ignores `limit`**. Don't recommend it on a query whose ordering or limit matters — it silently
changes behavior. Use `in_batches` with an explicit cursor if order matters.
**Verify:** stable memory under the operation; `derailed`/`memory_profiler` allocation drop.

### 5.2 `count` vs `length` vs `size` on relations
**Find:** `.length` on an un-loaded relation (loads all rows to count them).
**Fix:** `count` runs `SELECT COUNT(*)`; use `size` when records may already be loaded (it counts
in memory if loaded, else COUNTs). **Severity:** Low–Medium. **Verify:** query issued vs rows loaded.

---

## 6. Views & serialization

### 6.1 Rendering large collections without pagination or caching
**Find:** `index` actions returning unbounded collections; `render collection` with no cache.
**Fix:** paginate (kaminari/pagy) and/or fragment-cache. **Severity:** High on big lists.

### 6.2 N+1 inside serializers / JSON builders
**Find:** serializers or `jbuilder` templates accessing associations per record without preloading.
**Why:** the same N+1 as views, hidden in the API layer. **Fix:** preload the associations the
serializer touches. **Verify:** query count on the API endpoint.

---

## 7. Pagination

### 7.1 Deep OFFSET pagination
**Find:** offset-based pagination (`page`/`per`) used on large datasets reachable to deep pages.
**Why:** `OFFSET 100000 LIMIT 20` still scans and discards 100k rows — gets slower the deeper you go.
**Fix:** keyset / cursor pagination (`where("id < ?", last_id).order(id: :desc).limit(n)`) for deep
or infinite scroll. **Severity:** High on large, deeply-paged sets. **Verify:** EXPLAIN — constant-time
seek instead of a growing scan.

---

## 8. Pre-computation & memoization

### 8.1 Counting associations per request → counter cache
**Find:** `association.count` in views/loops (e.g. `category.products.count` per row).
**Fix:** `counter_cache: true` on the `belongs_to`; read the cached column. **Verify:** query count.
**Caveat:** it's not free — every child insert/delete now writes the parent row, so a hot parent
(a popular category's `products_count`) becomes a **write-contention / lock hotspot**, and counters can
**drift** under failures (`reset_counters` to repair). Weigh it against read frequency; for very hot
parents an async/periodic recount can beat a synchronous counter.

### 8.2 Recomputing the same value in a request → memoize
**Find:** an expensive method called multiple times per request.
**Fix:** `@x ||= expensive` (memoize). Scope to the request; don't memoize across requests in an
instance that persists. **Severity:** Low–Medium. **Verify:** call count / response time.

### 8.3 Expensive aggregates computed live → pre-compute
**Find:** dashboard/report aggregates recomputed on every view.
**Fix:** precompute on a schedule into a stats table/column; read the precomputed value.
**Severity:** Medium–High for heavy reports. **Verify:** response time; DB load.

---

## 9. Front-end (lightweight — this skill is back-end-first)

Flag, but keep brief, and say plainly that a front-end problem deserves a front-end pass rather
than a deep treatment here:
- **Render-blocking / asset weight:** large un-split JS, CSS not at top, JS not deferred.
- **Unoptimized images:** full-size images for thumbnails → Active Storage `variant(resize_to_limit:)`;
  missing `loading="lazy"` below the fold; no modern format (WebP/AVIF).
- **Missing cache headers** on static assets (Expires/Cache-Control) — check the CDN/Nginx config.
- **Long tasks / INP:** heavy synchronous JS on interaction; find them in the DevTools Performance
  panel (tasks >50ms).
**Verify:** Lighthouse (lab) then CrUX (field) at p75. Depth on Core Web Vitals is out of scope
here — see [web.dev/vitals](https://web.dev/articles/vitals) and the DevTools Performance and
Coverage panels.
