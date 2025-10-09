class UserLevel::Complete
  include Mandate

  initialize_with :user, :level

  def call
    UserLevel::FindOrCreate.(user, level).tap do |user_level|
      ActiveRecord::Base.transaction do
        user_level.update!(completed_at: Time.current)
        create_next_user_level!
      end

      # Send completion email asynchronously after transaction completes
      send_completion_email!(user_level)
    end
  end

  private
  def create_next_user_level!
    next_level = Level::FindNext.(level)
    return unless next_level

    UserLevel::FindOrCreate.(user, next_level)
  end

  def send_completion_email!(user_level)
    User::SendEmail.(user_level) do
      UserLevelMailer.with(user_level:).completed(user_level).deliver_later
    end
  end
end
