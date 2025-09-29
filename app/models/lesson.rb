class Lesson < ApplicationRecord
  disable_sti!

  belongs_to :level

  validates :slug, presence: true, uniqueness: true
  validates :title, presence: true
  validates :description, presence: true
  validates :type, presence: true
  validates :data, presence: true
  validates :position, presence: true, uniqueness: { scope: :level_id }

  before_validation :set_position, on: :create

  default_scope { order(:position) }

  private
  def set_position
    return if position.present?

    self.position = (level.lessons.maximum(:position) || 0) + 1 if level
  end
end
