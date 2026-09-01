# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  admin                  :boolean          default(FALSE), not null
#  bio                    :text
#  confirmation_sent_at   :datetime
#  confirmation_token     :string
#  confirmed_at           :datetime
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :inet
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  followers_count        :integer          default(0), not null
#  following_count        :integer          default(0), not null
#  gender                 :string
#  last_seen_at           :datetime
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :inet
#  name                   :string
#  phone                  :integer
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  sign_in_count          :integer          default(0), not null
#  unconfirmed_email      :string
#  username               :string
#  website                :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_users_on_confirmation_token    (confirmation_token) UNIQUE
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#
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
