module V1
  class UserLevelsController < ApplicationController
    def index
      user_levels = current_user.user_levels

      render json: {
        user_levels: SerializeUserLevels.(user_levels)
      }
    end
  end
end
