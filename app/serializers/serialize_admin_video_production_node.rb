class SerializeAdminVideoProductionNode
  include Mandate

  initialize_with :node

  def call
    {
      uuid: node.uuid,
      pipeline_uuid: node.pipeline.uuid,
      title: node.title,
      type: node.type,
      provider: node.provider,
      status: node.status,
      inputs: node.inputs,
      config: node.config,
      asset: node.asset,
      metadata: node.metadata,
      output: node.output,
      is_valid: node.is_valid,
      validation_errors: node.validation_errors,
      created_at: node.created_at.iso8601,
      updated_at: node.updated_at.iso8601
    }
  end
end
