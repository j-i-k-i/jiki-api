class V1::LessonsController < ApplicationController
  before_action :use_lesson!

  def show
    render json: {
      lesson: SerializeLesson.(@lesson)
    }
  end
end
