module V1
  class LevelsController < ApplicationController
    def index
      render json: {
        levels: SerializeLevels.(Level.all)
      }
    end
  end
end
