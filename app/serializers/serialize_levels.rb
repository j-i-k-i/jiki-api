class SerializeLevels
  include Mandate

  initialize_with :levels

  def call
    levels_with_includes.map do |level|
      SerializeLevel.(level)
    end
  end

  def levels_with_includes
    levels.to_active_relation.includes(:lessons)
  end
end
