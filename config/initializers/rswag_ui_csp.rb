class ContentSecurityPolicyExemption
  def initialize(app, path_prefix)
    @app = app
    @path_prefix = path_prefix
  end

  def call(env)
    if env["PATH_INFO"].to_s.start_with?(@path_prefix)
      env.delete(ActionDispatch::ContentSecurityPolicy::Request::POLICY)
    end

    @app.call(env)
  end
end

Rails.application.config.middleware.insert_before(
  ActionDispatch::ContentSecurityPolicy::Middleware,
  ContentSecurityPolicyExemption,
  "/api-docs"
)
