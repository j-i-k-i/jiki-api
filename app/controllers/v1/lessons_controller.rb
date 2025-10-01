module V1
  class LessonsController < ApplicationController
    before_action :use_lesson!

    def show
      render json: {
        lesson: SerializeLesson.(@lesson)
      }
    end
  end
end
