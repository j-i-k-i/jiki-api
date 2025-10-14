class V1::Admin::Levels::LessonsController < V1::Admin::BaseController
  before_action :set_level
  before_action :set_lesson, only: [:update]

  def index
    lessons = @level.lessons

    render json: {
      lessons: SerializeAdminLessons.(lessons)
    }
  end

  def update
    lesson = Lesson::Update.(@lesson, lesson_params)
    render json: {
      lesson: SerializeAdminLesson.(lesson)
    }
  rescue ActiveRecord::RecordInvalid => e
    render json: {
      error: {
        type: "validation_error",
        message: e.message
      }
    }, status: :unprocessable_entity
  end

  private
  def set_level
    @level = Level.find(params[:level_id])
  rescue ActiveRecord::RecordNotFound
    render json: {
      error: {
        type: "not_found",
        message: "Level not found"
      }
    }, status: :not_found
  end

  def set_lesson
    @lesson = @level.lessons.find_by!(id: params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: {
      error: {
        type: "not_found",
        message: "Lesson not found"
      }
    }, status: :not_found
  end

  def lesson_params
    params.require(:lesson).permit(:title, :description, :type, :position, data: {})
  end
end
