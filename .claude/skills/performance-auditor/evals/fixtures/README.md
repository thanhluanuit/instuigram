# Eval fixtures

Small, self-contained inputs so the evals in `../evals.json` are runnable without pointing the
skill at a private codebase.

## `rails-mini/`

A Rails-shaped directory tree — not a bootable app, just enough structure for the skill's scans
and schema inventory to work on. Every planted issue is marked `# PLANT:` in the source, and each
plant maps to a category the skill audits.

| Where | Plant | Category |
|---|---|---|
| `app/controllers/products_controller.rb#index` + `app/views/products/index.html.erb` | association loaded per row, no eager loading | N+1 |
| `app/views/products/index.html.erb` | `product.reviews.count` per row | N+1 / counter_cache |
| `app/controllers/products_controller.rb#show` | synchronous `Net::HTTP` in the request | Jobs |
| `app/services/order_report.rb` | `deliver_now` in the request path | Jobs |
| `app/services/order_report.rb#recalculate_all` | whole-table `.all.each` with per-row writes | Memory / Jobs |
| `app/models/product.rb#active_count` | loads every row to count them | Memory |
| `app/models/product.rb#active_names` | `.map(&:name)` instead of `.pluck` | N+1 |
| `db/structure.sql` | `orders.user_id`, `reviews.product_id` unindexed | Index |
| `config/database.yml` + `config/puma.rb` | pool 5 vs 4 workers × 16 threads | System |

**The traps** — these exist to catch false positives, and matter as much as the plants:

- The schema is `db/structure.sql`, **not** `db/schema.rb`. An agent that greps `add_index
  db/schema.rb` gets zero hits and may conclude nothing is indexed. That's eval 2a.
- `products.status` and `products.category_id` **are** indexed. Reporting them as missing is a
  false positive — eval 2b.
- Reach is not establishable from these files alone (no traffic data), so findings should carry
  `confidence: needs-measurement` rather than a confident Critical — eval 2d.

## `pg_stat_sample.csv`

A `pg_stat_statements` export shaped to match `rails-mini`, for
`scripts/runtime_evidence.py pgstat`. It should surface:

- `categories.id = $1` — 920k calls at 0.20ms → the N+1 behind the index page, and the largest
  single consumer of DB time.
- `COUNT(*) ... reviews.product_id = $1` — 880k calls → flagged as a counter_cache candidate
  rather than an eager-load, since the fix differs.
- `orders.user_id = $1` — only 4.2k calls but 17ms each → the unindexed filter. It ranks below
  the N+1s by call count but is second by total time, which is the point of ranking both ways.

**The calibration trap:** `users.id = $1` (610k calls, 0.02ms) *is* flagged by the N+1 detector,
and should **not** end up in the report. pg_stat_statements sees a query shape, not intent — it
cannot tell a per-row association load from a normal once-per-request `current_user` lookup, and
the fingerprint is identical. The agent is expected to rule it out by reading the code rather than
promoting every flagged shape into a finding; the script says as much in its own output ("Confirm
the source"). An agent that reports it has treated tool output as a verdict, which is the exact
failure the skill's "a scan hit is a candidate, not a finding" rule exists to prevent.

The `orders` UPDATE is present as ordinary write traffic and is correctly not flagged.
