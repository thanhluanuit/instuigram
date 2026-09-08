system_tests = ![ "", "0", "false", "off", "no" ].include?(ENV["SYSTEM_TESTS"].to_s.strip.downcase)

CI.run do
  step "Preflight: Ruby, credentials, services", "bin/ci-preflight"
  preflight_ok = success?

  step "Setup: Gems", "bundle check"
  step "Style: Ruby", "bin/rubocop"
  step "Security: Brakeman code analysis", "bundle exec brakeman"
  step "Security: Gem audit", "bundle exec bundle-audit check --update"

  if preflight_ok
    step "Setup: Test database", "bin/rails ci:prepare"
    step "Annotations: Model schema comments",
      "env RAILS_ENV=test bundle exec annotaterb models && git diff --exit-code app/models"
    step "Tests: Rails", "bin/rails test"

    if system_tests
      step "Setup: Clear tmp", "bin/rails tmp:clear"
      step "Tests: System", "bin/rails test:system"
    end
  else
    failure "Skipping the database and test steps",
      "The preflight above failed; fix what it listed and re-run bin/ci."
  end
end
