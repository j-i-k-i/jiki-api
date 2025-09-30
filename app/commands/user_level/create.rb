class UserLevel::Create
  include Mandate

  initialize_with :user, :level

  def call
    UserLevel.find_or_create_by!(user: user, level: level)
  end
end
