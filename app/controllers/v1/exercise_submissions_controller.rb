module V1
  class ExerciseSubmissionsController < ApplicationController
    before_action :use_lesson!

    def create
      # Find or create UserLesson for current user and lesson
      user_lesson = UserLesson::FindOrCreate.(current_user, @lesson)

      # Create submission
      ExerciseSubmission::Create.(
        user_lesson,
        submission_params[:files]
      )

      render json: {}, status: :created
    end

    private
    def submission_params
      params.require(:submission).permit(files: %i[filename code])
    end
  end
end
