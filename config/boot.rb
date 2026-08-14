ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.

# Rails 6.0/6.1's ActiveSupport::Logger internals reference the stdlib
# Logger constant before requiring it themselves; load it explicitly first
# (after bundler/setup so the Gemfile-pinned version is what gets activated).
require 'logger'

require 'bootsnap/setup' # Speed up boot time by caching expensive operations.
