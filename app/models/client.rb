# == Schema Information
#
# Table name: clients
#
#  id                   :bigint           not null, primary key
#  client_secret_digest :string           not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  client_id            :string           not null
#  user_id              :bigint           not null
#
class Client < ApplicationRecord
  belongs_to :user
  has_secure_password :client_secret

  before_create :generate_client_id
  before_validation :generate_plaintext_client_secret, on: :create

  private

  def generate_client_id
    self.client_id = SecureRandom.uuid
  end

  def generate_plaintext_client_secret
    self.client_secret ||= SecureRandom.hex(32)
  end
end
