# frozen_string_literal: true

module ApplicationHelper
  NAV_RAIL_PLACEHOLDERS = {
    "Activity" => "heart-o",
    "Saved" => "bookmark-o"
  }.freeze

  def nav_rail_link_options(section)
    active = nav_rail_active?(section)

    {
      class: class_names("app-rail__item", "is-active" => active),
      "aria-current": ("page" if active)
    }
  end

  private

  def nav_rail_active?(section)
    case section
    when :home     then current_page?(root_path)
    when :messages then controller_name == "conversations"
    when :explore  then controller_name.in?(%w[explore search])
    when :profile  then current_page?(user_path(current_user)) ||
                        current_page?(edit_user_path(current_user)) ||
                        current_page?(edit_user_registration_path)
    end
  end
end
