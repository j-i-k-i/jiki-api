class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::Allowlist

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
    :recoverable, :validatable,
    :jwt_authenticatable, jwt_revocation_strategy: self

  has_many :user_lessons, dependent: :destroy
  has_many :lessons, through: :user_lessons
  has_many :user_levels, dependent: :destroy
  has_many :levels, through: :user_levels
  has_many :refresh_tokens, class_name: "User::RefreshToken", dependent: :destroy

  belongs_to :current_user_level, class_name: "UserLevel", optional: true

  validates :locale, presence: true, inclusion: { in: %w[en hu] }
end
