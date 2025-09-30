module V1
  class LevelsController < ApplicationController
    skip_before_action :authenticate_user!, only: [:index]

    def index
      levels = Level.all

      render json: {
        levels: SerializeLevels.(levels)
      }
    end
  end
end
