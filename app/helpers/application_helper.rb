# frozen_string_literal: true

module ApplicationHelper
  def nav_rail_link_options(section)
    active = nav_rail_active?(section)

    {
      class: class_names("app-rail__item", "is-active" => active),
      "aria-current": ("page" if active)
    }
  end

  def nav_rail_active?(section)
    case section
    when :home     then controller_name == "home"
    when :messages then controller_name.in?(%w[conversations messages])
    when :profile  then controller_name == "users" || (controller_name == "registrations" && action_name == "edit")
    end
  end
end
