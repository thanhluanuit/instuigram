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
  has_many :following_relationships, class_name: "Follow",
                                     foreign_key: :follower_id, dependent: :destroy
  has_many :following, through: :following_relationships, source: :followed
  has_many :follower_relationships, class_name: "Follow",
                                    foreign_key: :followed_id, dependent: :destroy
  has_many :followers, through: :follower_relationships, source: :follower
  has_one_attached :avatar do |attachable|
    attachable.variant :thumb, resize_to_fill: [ 112, 112 ], preprocessed: true
    attachable.variant :large, resize_to_fill: [ 280, 280 ], preprocessed: true
  end

  validates :website, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }, allow_blank: true
  validates :avatar, image: true

  before_destroy :destroy_conversations

  scope :suggested_for, ->(user) {
    where.not(id: user.id)
      .where.not(id: Follow.select(:followed_id).where(follower_id: user.id))
      .where.not(username: [ nil, "" ])
      .order(followers_count: :desc, id: :asc)
  }

  scope :matching_username, ->(query) {
    next all if query.blank?

    where("username ILIKE ?", "%#{sanitize_sql_like(query)}%")
  }

  def online?
    last_seen_at.present? && last_seen_at > 1.minute.ago
  end

  def following?(user)
    following_relationships.exists?(followed_id: user.id)
  end

  def unread_messages_count
    conversation_participants.sum(:unread_count)
  end

  private

  def destroy_conversations
    Conversation.where(id: conversations.ids).destroy_all
  end
end
