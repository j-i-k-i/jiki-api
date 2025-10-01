module V1
  class LessonsController < ApplicationController
    def show
      lesson = Lesson.find_by!(slug: params[:slug])

      render json: {
        lesson: SerializeLesson.(lesson)
      }
    end
  end
end
