# == Schema Information
#
# Table name: conversation_participants
#
#  id              :bigint           not null, primary key
#  unread_count    :integer          default(0), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  conversation_id :bigint           not null
#  user_id         :bigint           not null
#
class ConversationParticipant < ApplicationRecord
  belongs_to :conversation
  belongs_to :user

  def self.unread_totals_for(user_ids)
    where(user_id: user_ids).group(:user_id).sum(:unread_count)
  end
end
