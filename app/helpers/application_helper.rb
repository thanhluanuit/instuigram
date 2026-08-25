module ApplicationHelper
  def nav_active?(*controllers)
    controllers.include?(controller_name)
  end
end
