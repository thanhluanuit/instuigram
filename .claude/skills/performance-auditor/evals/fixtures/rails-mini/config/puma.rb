max_threads_count = ENV.fetch("RAILS_MAX_THREADS", 16)
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }
threads min_threads_count, max_threads_count

workers ENV.fetch("WEB_CONCURRENCY", 4)
preload_app!

port ENV.fetch("PORT", 3000)
environment ENV.fetch("RAILS_ENV", "development")

# 4 workers × 16 threads = 64 connections per server, against a pool of 5
# in config/database.yml. See the plant note there.
