class LevelDrop < Liquid::Drop
  # rubocop:disable Lint/MissingSuper
  def initialize(level)
    @level = level
  end
  # rubocop:enable Lint/MissingSuper

  delegate :title, to: :@level

  delegate :description, to: :@level

  delegate :slug, to: :@level

  delegate :position, to: :@level
end
