module V1
  class LevelsController < ApplicationController
    def index
      levels = Level.all

      render json: {
        levels: SerializeLevels.(levels)
      }
    end
  end
end
