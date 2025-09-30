class Level::FindNext
  include Mandate

  initialize_with :current_level

  def call
    Level.where("position > ?", current_level.position).order(:position).first
  end
end
