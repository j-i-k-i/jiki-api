class SerializeAdminVideoProductionNode
  include Mandate

  initialize_with :node

  def call
    {
      uuid: node.uuid,
      pipeline_uuid: node.pipeline.uuid,
      title: node.title,
      type: node.type,
      status: node.status,
      inputs: node.inputs,
      config: node.config,
      asset: node.asset,
      metadata: node.metadata,
      output: node.output,
      created_at: node.created_at.iso8601,
      updated_at: node.updated_at.iso8601
    }
  end
end
