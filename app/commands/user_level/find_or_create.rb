class UserLevel::FindOrCreate
  include Mandate

  initialize_with :user, :level

  def call
    UserLevel.find_create_or_find_by!(user: user, level: level) do |ul|
      ul.started_at = Time.current
    end
  end
end
