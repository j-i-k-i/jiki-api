module V1
  class UserLessonsController < ApplicationController
    before_action :use_lesson!

    def show
      user_lesson = UserLesson.find_by(user: current_user, lesson: @lesson)

      return render_not_found unless user_lesson

      render json: {
        user_lesson: SerializeUserLesson.(user_lesson)
      }
    end

    def start
      UserLesson::FindOrCreate.(current_user, @lesson)

      render json: {}
    end

    def complete
      UserLesson::Complete.(current_user, @lesson)

      render json: {}
    end

    private
    def render_not_found
      render json: {
        error: {
          type: "not_found",
          message: "User lesson not found"
        }
      }, status: :not_found
    end
  end
end
