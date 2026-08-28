class ConversationParticipant < ApplicationRecord
  belongs_to :conversation
  belongs_to :user

  def self.unread_totals_for(user_ids)
    where(user_id: user_ids).group(:user_id).sum(:unread_count)
  end
end
