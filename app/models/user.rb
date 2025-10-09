class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :validatable,
    :jwt_authenticatable, jwt_revocation_strategy: self

  has_many :user_lessons, dependent: :destroy
  has_many :lessons, through: :user_lessons
  has_many :user_levels, dependent: :destroy
  has_many :levels, through: :user_levels

  belongs_to :current_user_level, class_name: "UserLevel", optional: true

  validates :locale, presence: true, inclusion: { in: %w[en hu] }

  # Placeholder for email preferences - always allow emails for now
  # TODO: Implement actual email preferences when communication_preferences are built
  def may_receive_emails?
    true
  end

  # Placeholder for communication preferences - will be implemented later
  def communication_preferences
    nil
  end
end
