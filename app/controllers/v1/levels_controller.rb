module V1
  class LevelsController < ApplicationController
    def index
      levels = Level.all

      render json: {
        levels: SerializeLevels.(levels),
        current_level_slug: current_user.current_user_level&.level&.slug,
        current_lesson_slug: current_user.current_user_level&.current_user_lesson&.lesson&.slug
      }
    end
  end
end
