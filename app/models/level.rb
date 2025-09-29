class Level < ApplicationRecord
  disable_sti!

  has_many :lessons, -> { order(:position) }, dependent: :destroy, inverse_of: :level
  has_many :user_levels, dependent: :destroy
  has_many :users, through: :user_levels

  validates :slug, presence: true, uniqueness: true
  validates :title, presence: true
  validates :description, presence: true
  validates :position, presence: true, uniqueness: true

  before_validation :set_position, on: :create

  default_scope { order(:position) }

  private
  def set_position
    return if position.present?

    self.position = (self.class.maximum(:position) || 0) + 1
  end
end
