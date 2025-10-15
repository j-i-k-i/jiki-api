class SerializeAdminVideoProductionPipeline
  include Mandate

  initialize_with :pipeline, include_nodes: false

  def call
    {
      uuid: pipeline.uuid,
      title: pipeline.title,
      version: pipeline.version,
      config: pipeline.config,
      metadata: pipeline.metadata,
      created_at: pipeline.created_at.iso8601,
      updated_at: pipeline.updated_at.iso8601
    }.tap do |hash|
      hash[:nodes] = SerializeAdminVideoProductionNodes.(pipeline.nodes) if include_nodes
    end
  end
end
