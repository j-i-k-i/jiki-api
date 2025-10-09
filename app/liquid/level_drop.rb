class LevelDrop < Liquid::Drop
  # rubocop:disable Lint/MissingSuper
  def initialize(level)
    @level = level
  end
  # rubocop:enable Lint/MissingSuper

  delegate :title, :description, :slug, :position, to: :@level
end
