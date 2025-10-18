class VideoProduction::Node::Schemas::Asset
  INPUTS = {
    # Asset nodes have no inputs - they are source nodes
  }.freeze

  # Assets don't have provider-specific config
  PROVIDER_CONFIGS = {
    'direct' => {}
  }.freeze
end
