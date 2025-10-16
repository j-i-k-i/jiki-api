class ApplicationController < ActionController::API
  before_action :authenticate_user!

  private
  def authenticate_user!
    # Don't interfere with Devise's own controllers
    return super if devise_controller?

    # Only allow URL-based authentication in development
    return super unless Rails.env.development?
    return super unless params[:user_id].present?

    # Development-only: Allow authentication via user_id query parameter
    user = User.find_by(id: params[:user_id])
    return super unless user

    sign_in(user, store: false)
    Rails.logger.warn "[DEV AUTH] Authenticated as user #{user.id} via URL parameter"
  end

  def use_lesson!
    @lesson = Lesson.find_by!(slug: params[:lesson_slug])
  rescue ActiveRecord::RecordNotFound
    render json: {
      error: {
        type: "not_found",
        message: "Lesson not found"
      }
    }, status: :not_found
  end

  def render_not_found(message)
    render json: {
      error: {
        type: "not_found",
        message: message
      }
    }, status: :not_found
  end
end
