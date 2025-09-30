module V1
  class UserLessonsController < ApplicationController
    before_action :use_lesson!

    def start
      UserLesson::FindOrCreate.(current_user, @lesson)

      render json: {}
    end

    def complete
      UserLesson::Complete.(current_user, @lesson)

      render json: {}
    end
  end
end
