CI.run do
  step "Services: Postgres, Redis, Elasticsearch", "bin/ci-services"
  step "Setup: Gems", "bundle check"
  step "Style: Ruby", "bin/rubocop"
  step "Security: Brakeman code analysis", "bundle exec brakeman"
  step "Security: Gem audit", "bundle exec bundle-audit check --update"
  step "Setup: Test database", "bin/rails ci:prepare"
  step "Tests: Rails", "bin/rails test"
  step "Annotations: Model schema comments",
    "env RAILS_ENV=test bundle exec annotaterb models && git diff --exit-code app/models"

  if ENV["SYSTEM_TESTS"]
    step "Setup: Test database", "bin/rails ci:prepare"
    step "Tests: System", "bin/rails test:system"
  end
end
