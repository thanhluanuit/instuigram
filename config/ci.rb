system_tests = ![ "", "0", "false", "off", "no" ].include?(ENV["SYSTEM_TESTS"].to_s.strip.downcase)

CI.run do
  step "Preflight: Ruby, credentials, services", "bin/ci-preflight"
  step "Setup: Gems", "bundle check"
  step "Style: Ruby", "bin/rubocop"
  step "Security: Brakeman code analysis", "bundle exec brakeman"
  step "Security: Gem audit", "bundle exec bundle-audit check --update"
  step "Setup: Test database", "bin/rails ci:prepare"
  step "Tests: Rails", "bin/rails test"
  step "Annotations: Model schema comments",
    "env RAILS_ENV=test bundle exec annotaterb models && git diff --exit-code app/models"

  if system_tests
    step "Setup: Test database", "bin/rails ci:prepare"
    step "Tests: System", "bin/rails test:system"
  end
end
