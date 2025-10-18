require "test_helper"

class VideoProduction::Node::ValidateTest < ActiveSupport::TestCase
  test "returns valid for merge-videos node with valid inputs" do
    pipeline = create(:video_production_pipeline)
    input1 = create(:video_production_node, pipeline:)
    input2 = create(:video_production_node, pipeline:)
    node = create(:video_production_node,
      pipeline:,
      type: 'merge-videos',
      provider: 'ffmpeg',
      inputs: { 'segments' => [input1.uuid, input2.uuid] })

    result = VideoProduction::Node::Validate.(node)

    assert result[:is_valid]
    assert_empty result[:validation_errors]
  end

  test "returns invalid for merge-videos node with insufficient segments" do
    pipeline = create(:video_production_pipeline)
    input1 = create(:video_production_node, pipeline:)
    node = create(:video_production_node,
      pipeline:,
      type: 'merge-videos',
      provider: 'ffmpeg',
      inputs: { 'segments' => [input1.uuid] })

    result = VideoProduction::Node::Validate.(node)

    refute result[:is_valid]
    assert_equal "requires at least 2 items, got 1", result[:validation_errors][:segments]
  end

  test "returns invalid for merge-videos node with non-existent node references" do
    pipeline = create(:video_production_pipeline)
    node = create(:video_production_node,
      pipeline:,
      type: 'merge-videos',
      provider: 'ffmpeg',
      inputs: { 'segments' => %w[fake-uuid-1 fake-uuid-2] })

    result = VideoProduction::Node::Validate.(node)

    refute result[:is_valid]
    assert_match(/references non-existent nodes/, result[:validation_errors][:segments])
  end

  test "returns valid for asset node type" do
    pipeline = create(:video_production_pipeline)
    node = create(:video_production_node, pipeline:, type: 'asset', provider: 'direct', inputs: {})

    result = VideoProduction::Node::Validate.(node)

    assert result[:is_valid]
    assert_empty result[:validation_errors]
  end

  test "returns invalid for truly unknown node type" do
    pipeline = create(:video_production_pipeline)
    # Create a node with an unknown type bypassing validation
    node = VideoProduction::Node.new(
      pipeline:,
      type: 'completely-unknown-type',
      provider: 'unknown-provider',
      title: 'Test Node',
      uuid: SecureRandom.uuid
    )
    node.save(validate: false)

    result = VideoProduction::Node::Validate.(node)

    refute result[:is_valid]
    assert_equal "Unknown node type: completely-unknown-type", result[:validation_errors][:invalid_type]
  end

  test "persists validation state to node via Create command" do
    pipeline = create(:video_production_pipeline)
    input1 = create(:video_production_node, pipeline:)
    input2 = create(:video_production_node, pipeline:)

    node = VideoProduction::Node::Create.(pipeline, {
      type: 'merge-videos',
      provider: 'ffmpeg',
      title: 'Test Node',
      inputs: { 'segments' => [input1.uuid, input2.uuid] }
    })

    # is_valid should be set after creation via Create command
    assert node.is_valid?
    assert_empty node.validation_errors
  end

  test "persists invalid nodes via Create command" do
    pipeline = create(:video_production_pipeline)

    node = VideoProduction::Node::Create.(pipeline, {
      type: 'merge-videos',
      provider: 'ffmpeg',
      title: 'Invalid Node',
      inputs: { 'segments' => [] }
    })

    refute node.is_valid?
    assert node.validation_errors['segments'].present?
  end

  test "returns invalid for unknown provider for node type" do
    pipeline = create(:video_production_pipeline)
    node = create(:video_production_node,
      pipeline:,
      type: 'merge-videos',
      provider: 'invalid-provider',
      inputs: {})

    result = VideoProduction::Node::Validate.(node)

    refute result[:is_valid]
    assert_equal "Unknown provider 'invalid-provider' for merge-videos nodes", result[:validation_errors][:provider]
  end

  test "validates provider-specific config requirements" do
    pipeline = create(:video_production_pipeline)
    node = create(:video_production_node,
      pipeline:,
      type: 'generate-talking-head',
      provider: 'heygen',
      config: {})

    result = VideoProduction::Node::Validate.(node)

    refute result[:is_valid]
    assert result[:validation_errors][:avatar_id].present?
    assert result[:validation_errors][:voice_id].present?
  end
end
