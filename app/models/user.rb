class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :posts, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :reactions, dependent: :destroy
  has_many :clients, dependent: :destroy
  has_many :event_logs, dependent: :destroy
  has_many :conversation_participants
  has_many :conversations, through: :conversation_participants
  has_many :messages, dependent: :destroy
  has_one_attached :avatar

  validates :website, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }, allow_blank: true
  validates :avatar, image: true

  before_destroy :destroy_conversations

  scope :matching_username, ->(query) {
    next all if query.blank?

    where("username ILIKE ?", "%#{sanitize_sql_like(query)}%")
  }

  def online?
    last_seen_at.present? && last_seen_at > 1.minute.ago
  end

  def unread_messages_count
    conversation_participants.sum(:unread_count)
  end

  private

  def destroy_conversations
    Conversation.where(id: conversations.ids).destroy_all
  end
end
