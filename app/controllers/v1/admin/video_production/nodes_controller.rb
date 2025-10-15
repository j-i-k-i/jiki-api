class V1::Admin::VideoProduction::NodesController < V1::Admin::BaseController
  before_action :use_pipeline
  before_action :use_node, only: %i[show update destroy]

  def index
    nodes = @pipeline.nodes.order(:created_at)

    render json: {
      nodes: SerializeAdminVideoProductionNodes.(nodes)
    }
  end

  def show
    render json: {
      node: SerializeAdminVideoProductionNode.(@node)
    }
  end

  def create
    node = VideoProduction::Node::Create.(
      @pipeline,
      params.require(:node).permit(:title, :type, inputs: {}, config: {}, asset: {})
    )
    render json: {
      node: SerializeAdminVideoProductionNode.(node)
    }, status: :created
  rescue VideoProductionBadInputsError => e
    render json: {
      error: {
        type: "validation_error",
        message: e.message
      }
    }, status: :unprocessable_entity
  rescue ActiveRecord::RecordInvalid => e
    render json: {
      error: {
        type: "validation_error",
        message: e.message
      }
    }, status: :unprocessable_entity
  end

  def update
    node = VideoProduction::Node::Update.(
      @node,
      params.require(:node).permit(:title, inputs: {}, config: {}, asset: {})
    )
    render json: {
      node: SerializeAdminVideoProductionNode.(node)
    }
  rescue VideoProductionBadInputsError => e
    render json: {
      error: {
        type: "validation_error",
        message: e.message
      }
    }, status: :unprocessable_entity
  rescue ActiveRecord::RecordInvalid => e
    render json: {
      error: {
        type: "validation_error",
        message: e.message
      }
    }, status: :unprocessable_entity
  end

  def destroy
    VideoProduction::Node::Destroy.(@node)
    head :no_content
  end

  private
  def use_pipeline
    @pipeline = VideoProduction::Pipeline.find_by!(uuid: params[:pipeline_uuid])
  rescue ActiveRecord::RecordNotFound
    render json: {
      error: {
        type: "not_found",
        message: "Pipeline not found"
      }
    }, status: :not_found
  end

  def use_node
    @node = @pipeline.nodes.find_by!(uuid: params[:uuid])
  rescue ActiveRecord::RecordNotFound
    render json: {
      error: {
        type: "not_found",
        message: "Node not found"
      }
    }, status: :not_found
  end
end
