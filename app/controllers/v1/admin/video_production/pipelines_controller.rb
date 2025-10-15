class V1::Admin::VideoProduction::PipelinesController < V1::Admin::BaseController
  before_action :use_pipeline, only: %i[show update destroy]

  def index
    pipelines = VideoProduction::Pipeline.
      order(updated_at: :desc).
      page(params[:page]).
      per(params[:per] || 25)

    render json: SerializePaginatedCollection.(
      pipelines,
      serializer: SerializeAdminVideoProductionPipelines
    )
  end

  def show
    render json: {
      pipeline: SerializeAdminVideoProductionPipeline.(@pipeline, include_nodes: true)
    }
  end

  def create
    pipeline = VideoProduction::Pipeline::Create.(pipeline_params.to_h)
    render json: {
      pipeline: SerializeAdminVideoProductionPipeline.(pipeline)
    }, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: {
      error: {
        type: "validation_error",
        message: e.message
      }
    }, status: :unprocessable_entity
  end

  def update
    pipeline = VideoProduction::Pipeline::Update.(@pipeline, pipeline_params.to_h)
    render json: {
      pipeline: SerializeAdminVideoProductionPipeline.(pipeline)
    }
  rescue ActiveRecord::RecordInvalid => e
    render json: {
      error: {
        type: "validation_error",
        message: e.message
      }
    }, status: :unprocessable_entity
  end

  def destroy
    VideoProduction::Pipeline::Destroy.(@pipeline)
    head :no_content
  end

  private
  def use_pipeline
    @pipeline = VideoProduction::Pipeline.find_by!(uuid: params[:uuid])
  rescue ActiveRecord::RecordNotFound
    render json: {
      error: {
        type: "not_found",
        message: "Pipeline not found"
      }
    }, status: :not_found
  end

  def pipeline_params
    params.require(:pipeline).permit(:title, :version, config: {}, metadata: {})
  end
end
