class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :validatable,
    :jwt_authenticatable, jwt_revocation_strategy: self

  # Generate a unique JTI (JWT ID) for each user on creation
  before_create :generate_jti

  private
  def generate_jti
    self.jti = SecureRandom.uuid
  end
end
