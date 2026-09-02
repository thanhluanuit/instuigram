# == Schema Information
#
# Table name: messages
#
#  id              :bigint           not null, primary key
#  body            :text             not null
#  key             :uuid             not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  conversation_id :bigint           not null
#  user_id         :bigint           not null
#
class Message < ApplicationRecord
  include Keyable

  belongs_to :conversation
  belongs_to :user

  validates :body, presence: true, length: { maximum: 1000 }

  scope :chronological, -> { order(:created_at, :id) }
end
