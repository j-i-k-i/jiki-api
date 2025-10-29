class V1::ConceptsController < ApplicationController
  before_action :use_concept, only: [:show]

  def index
    user = params[:unscoped] == "true" ? nil : current_user

    concepts = Concept::Search.(
      title: params[:title],
      page: params[:page],
      per: params[:per],
      user:
    )

    render json: SerializePaginatedCollection.(
      concepts,
      serializer: SerializeConcepts
    )
  end

  def show
    unless params[:unscoped] == "true" || current_user.unlocked_concept_ids.include?(@concept.id)
      render json: { error: "This concept is locked" }, status: :forbidden
      return
    end

    render json: {
      concept: SerializeConcept.(@concept)
    }
  end

  private
  def use_concept
    @concept = Concept.friendly.find(params[:slug])
  rescue ActiveRecord::RecordNotFound
    render_not_found("Concept not found")
  end
end
