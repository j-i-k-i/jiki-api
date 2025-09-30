class ApplicationController < ActionController::API
  before_action :authenticate_user!

  private
  def use_lesson!
    @lesson = Lesson.find_by!(slug: params[:slug])
  rescue ActiveRecord::RecordNotFound
    render json: {
      error: {
        type: "not_found",
        message: "Lesson not found"
      }
    }, status: :not_found
  end
end
