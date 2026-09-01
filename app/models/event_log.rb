# == Schema Information
#
# Table name: event_logs
#
#  id           :bigint           not null, primary key
#  event_type   :string           not null
#  ip_address   :inet             not null
#  subject_type :string           not null
#  user_agent   :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  subject_id   :bigint           not null
#  user_id      :bigint           not null
#
# Indexes
#
#  index_event_logs_on_subject  (subject_type,subject_id)
#  index_event_logs_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class EventLog < ApplicationRecord
  EVENT_TYPES = {
    post_created: "post_created",
    post_destroyed: "post_destroyed",
    profile_updated: "profile_updated",
    comment_created: "comment_created",
    reaction_created: "reaction_created",
    message_sent: "message_sent",
    follow_created: "follow_created"
  }.freeze

  belongs_to :user
  belongs_to :subject, polymorphic: true, optional: true

  enum :event_type, EVENT_TYPES

  validates :subject_type, :subject_id, presence: true
end
