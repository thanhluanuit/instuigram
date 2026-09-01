# frozen_string_literal: true

class Rack3CspHeaderNormalizer
  LEGACY_NAMES = {
    "Content-Security-Policy" => ActionDispatch::Constants::CONTENT_SECURITY_POLICY,
    "Content-Security-Policy-Report-Only" => ActionDispatch::Constants::CONTENT_SECURITY_POLICY_REPORT_ONLY
  }.freeze

  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, body = @app.call(env)

    LEGACY_NAMES.each do |legacy, normalized|
      headers[normalized] = headers.delete(legacy) if headers.key?(legacy)
    end

    [ status, headers, body ]
  end
end
