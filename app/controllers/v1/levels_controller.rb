class V1::LevelsController < ApplicationController
  def index
    render json: {
      levels: SerializeLevels.(Level.all)
    }
  end
end
