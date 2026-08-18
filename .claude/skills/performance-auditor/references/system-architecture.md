# System & Architecture Performance Checks

Covers the `System` category — last in Mode B's category order — and whenever the user asks a
scaling question ("will this hold under 2× traffic?"). These are config- and architecture-level,
not per-request. Confirm each from files in the repo (`config/database.yml`, `config/puma.rb`,
`config/environments/production.rb`, `config/cable.yml`, and the schema dump — `db/schema.rb`
**or** `db/structure.sql`, whichever the repo uses) plus any production signals the user shares.

## 1. Database connection pool (check first — the #1 silent bottleneck)
**Check:** in `config/database.yml`, `pool` should be **≥ the app server's thread count**
(`RAILS_MAX_THREADS`). Then compute total connections: `servers × workers × threads`
(web **and** background workers) and compare to Postgres `max_connections`.
**Why it bites:** if `pool < threads`, threads queue for connections →
`ActiveRecord::ConnectionTimeoutError` and requests stalling with *low* CPU and *low* query
time (they're waiting to *get* a connection, not to run one). If total connections exceed
`max_connections`, new checkouts fail.
**Fix:** set `pool = threads`; if the total approaches `max_connections`, put **PgBouncer**
(transaction pooling) in front — and set `prepared_statements: false`, since transaction
pooling breaks server-side prepared statements.
**Finding:** `category: System`, severity by how close total is to the limit.

## 2. Read replicas (read-heavy apps hitting one primary)
**Check:** is the app read-dominant (search, listings, dashboards) and pointed at a single DB?
**Why:** a single primary eventually caps read throughput. **Fix:** Rails multi-database — a
`replica: true` connection, `connects_to database: { writing:, reading: }`, and either the
`DatabaseSelector` middleware (auto-routes GETs to the replica, recent writers back to primary
to dodge lag) or explicit `connected_to(role: :reading)`. **Caveat:** replica lag → read-your-
writes staleness; force `:writing` where correctness needs it. **When worth it:** only once the
primary is genuinely read-saturated — not day one.

## 3. Cache & queue backends
**Cache store** (`config/environments/production.rb`): a real shared store (Redis / Memcached /
Solid Cache), not `:memory_store` (which is per-process and invisible across servers). Redis must
have `maxmemory` + an eviction policy or it OOMs. Solid Cache (DB-backed) trades a service for
disk-backed capacity.
**Queue backend:** Sidekiq (Redis) or Solid Queue (DB). Background workers **also consume DB
connections** — size their pool like web (§1); a busy worker fleet is a common hidden cause of
pool exhaustion. Separate queues by priority (`critical` / `default` / `low`) so bulk jobs never
delay user-facing ones. **Track time-in-queue as an SLA**, not just job runtime — a job that
takes 10 min to *start* is a user-visible failure.

## 4. App server sizing (light touch)
**Check:** `config/puma.rb` — `pool`/`RAILS_MAX_THREADS` must line up with §1. Watch for
**request queuing**: if requests wait before Rails starts handling them, the fix is more capacity
(workers/servers), not faster code. Read it from `Puma.stats` (`backlog` > 0 and
`pool_capacity` at 0 mean requests are waiting on a thread), or from the load balancer's
queue/wait metric. (Detailed worker/thread tuning is out of scope here — flag the symptom and the
pool alignment; leave sizing to an infra pass.)

## 5. External dependencies in the hot path
**Check:** synchronous third-party HTTP calls inside web requests (payment, search, email APIs).
**Why:** the slowest external dependency sets your response time and your failure rate.
**Fix:** move to jobs, add timeouts + circuit breakers, cache responses where safe. **Verify:**
controller response time drops by roughly the external call's duration, and the endpoint's
response time stops tracking the third party's availability.

## 6. Capacity — measure the ceiling before you need it
For "will it scale" questions, don't reason in the abstract — **load-test** (k6/JMeter) a realistic
traffic mix, ramp until p95 latency spikes or errors appear, and read *what breaks first*: pool
exhaustion (§1), CPU-bound app servers (add capacity), or Redis/DB saturation (scale the backend).
The failure *mode* is the finding. Provision for expected peak with headroom (~60–70% utilization
at peak, not 100%).

## Cost note
Before recommending "scale up", confirm the resource is actually the limit — adding instances to a
pool-exhaustion or N+1 problem burns budget without fixing latency. Fix the code, then size the fleet.
