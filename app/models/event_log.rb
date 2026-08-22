class EventLog < ApplicationRecord
  EVENT_TYPES = {
    post_created: "post_created",
    post_destroyed: "post_destroyed",
    profile_updated: "profile_updated",
    comment_created: "comment_created",
    reaction_created: "reaction_created"
  }.freeze

  belongs_to :user
  belongs_to :subject, polymorphic: true

  enum :event_type, EVENT_TYPES
end
