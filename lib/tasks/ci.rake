namespace :ci do
  desc "Purge and reload the test database, drop stale parallel worker databases, and clear tmp"
  task :prepare do
    attempts = 0

    begin
      attempts += 1
      %w[db:test:prepare db:test:load_schema db:test:purge ci:drop_worker_databases]
        .each { |name| Rake::Task[name].reenable }

      Rake::Task["db:test:prepare"].invoke
      Rake::Task["ci:drop_worker_databases"].invoke
    rescue ActiveRecord::StatementInvalid => error
      raise if attempts >= 5 || !error.cause.is_a?(PG::ObjectInUse)

      sleep 1
      retry
    end

    Rake::Task["tmp:clear"].invoke
  end

  desc "Drop the parallel test worker databases so they are rebuilt from the current schema"
  task drop_worker_databases: "db:load_config" do
    db_config = ActiveRecord::Base.configurations.configs_for(env_name: "test", name: "primary")
    workers = ENV["PARALLEL_WORKERS"]&.to_i ||
      (Concurrent.available_processor_count || Concurrent.processor_count).floor

    workers.times do |index|
      worker_config = ActiveRecord::DatabaseConfigurations::HashConfig.new(
        db_config.env_name,
        db_config.name,
        db_config.configuration_hash.merge(database: "#{db_config.database}_#{index}")
      )

      ActiveRecord::Tasks::DatabaseTasks.drop(worker_config)
    end
  end
end
