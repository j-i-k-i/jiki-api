module V1
  class LessonsController < ApplicationController
    before_action :use_lesson!

    def start
      user_lesson = UserLesson::FindOrCreate.(current_user, @lesson)

      render json: {
        user_lesson: {
          id: user_lesson.id,
          lesson_id: user_lesson.lesson_id,
          started_at: user_lesson.started_at,
          completed_at: user_lesson.completed_at
        }
      }, status: :created
    end

    def complete
      user_lesson = UserLesson::Complete.(current_user, @lesson)

      render json: {
        user_lesson: {
          id: user_lesson.id,
          lesson_id: user_lesson.lesson_id,
          started_at: user_lesson.started_at,
          completed_at: user_lesson.completed_at
        }
      }, status: :ok
    end
  end
end
