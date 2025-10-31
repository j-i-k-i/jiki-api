class Internal::ConceptsController < Internal::BaseController
  before_action :use_concept!, only: [:show]

  def index
    concepts = Concept::Search.(
      title: params[:title],
      page: params[:page],
      per: params[:per],
      user: current_user
    )

    render json: SerializePaginatedCollection.(
      concepts,
      serializer: SerializeConcepts
    )
  end

  def show
    unless current_user.unlocked_concept_ids.include?(@concept.id)
      render json: { error: "This concept is locked" }, status: :forbidden
      return
    end

    render json: {
      concept: SerializeConcept.(@concept)
    }
  end
end
