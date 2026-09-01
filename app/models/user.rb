class User < ApplicationRecord
  include Followable
  include Conversable

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :posts, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :reactions, dependent: :destroy
  has_many :clients, dependent: :destroy
  has_many :event_logs, dependent: :destroy
  has_one_attached :avatar do |attachable|
    attachable.variant :thumb, resize_to_fill: [ 112, 112 ], preprocessed: true
    attachable.variant :large, resize_to_fill: [ 280, 280 ], preprocessed: true
  end

  validates :website, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }, allow_blank: true
  validates :avatar, image: true

  scope :matching_username, ->(query) {
    next all if query.blank?

    where("username ILIKE ?", "%#{sanitize_sql_like(query)}%")
  }

  def online?
    last_seen_at.present? && last_seen_at > 1.minute.ago
  end
end
