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
# Indexes
#
#  index_conversation_participants_on_conversation_id_and_user_id  (conversation_id,user_id) UNIQUE
#  index_conversation_participants_on_user_id_and_unread_count     (user_id,unread_count)
#
# Foreign Keys
#
#  fk_rails_...  (conversation_id => conversations.id)
#  fk_rails_...  (user_id => users.id)
#
class ConversationParticipant < ApplicationRecord
  belongs_to :conversation
  belongs_to :user

  def self.unread_totals_for(user_ids)
    where(user_id: user_ids).group(:user_id).sum(:unread_count)
  end
end
