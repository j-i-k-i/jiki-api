require "test_helper"

class VideoProduction::Node::ValidateInputsTest < ActiveSupport::TestCase
  test "returns valid for asset node with no inputs" do
    node = build(:video_production_node, type: 'asset', inputs: {})

    result = VideoProduction::Node::ValidateInputs.(node)

    assert result[:valid]
    assert_empty result[:errors]
  end

  test "returns invalid for asset node with inputs" do
    node = build(:video_production_node, type: 'asset', inputs: { 'foo' => ['bar'] })

    result = VideoProduction::Node::ValidateInputs.(node)

    refute result[:valid]
    assert_includes result[:errors], "asset nodes should not have inputs"
  end

  test "returns invalid for unknown node type" do
    node = build(:video_production_node, type: 'unknown-type')

    result = VideoProduction::Node::ValidateInputs.(node)

    refute result[:valid]
    assert_includes result[:errors], "Unknown node type: unknown-type"
  end

  # merge-videos tests
  test "returns valid for merge-videos with valid segments" do
    pipeline = create(:video_production_pipeline)
    input1 = create(:video_production_node, pipeline: pipeline)
    input2 = create(:video_production_node, pipeline: pipeline)
    node = create(:video_production_node,
      pipeline: pipeline,
      type: 'merge-videos',
      inputs: { 'segments' => [input1.uuid, input2.uuid] })

    result = VideoProduction::Node::ValidateInputs.(node)

    assert result[:valid], "Expected valid, got errors: #{result[:errors]}"
    assert_empty result[:errors]
  end

  test "returns invalid for merge-videos without segments" do
    node = build(:video_production_node, type: 'merge-videos', inputs: {})

    result = VideoProduction::Node::ValidateInputs.(node)

    refute result[:valid]
    assert_includes result[:errors], "Input 'segments' is required for merge-videos nodes"
  end

  test "returns invalid for merge-videos with only one segment" do
    pipeline = create(:video_production_pipeline)
    input1 = create(:video_production_node, pipeline: pipeline)
    node = create(:video_production_node,
      pipeline: pipeline,
      type: 'merge-videos',
      inputs: { 'segments' => [input1.uuid] })

    result = VideoProduction::Node::ValidateInputs.(node)

    refute result[:valid]
    assert_includes result[:errors], "Input 'segments' requires at least 2 item(s), got 1"
  end

  test "returns invalid for merge-videos with non-existent node UUIDs" do
    pipeline = create(:video_production_pipeline)
    node = create(:video_production_node,
      pipeline: pipeline,
      type: 'merge-videos',
      inputs: { 'segments' => %w[fake-uuid-1 fake-uuid-2] })

    result = VideoProduction::Node::ValidateInputs.(node)

    refute result[:valid]
    assert_match(/Input 'segments' references non-existent nodes/, result[:errors].join)
  end

  test "returns invalid for merge-videos with non-array segments" do
    node = build(:video_production_node,
      type: 'merge-videos',
      inputs: { 'segments' => 'not-an-array' })

    result = VideoProduction::Node::ValidateInputs.(node)

    refute result[:valid]
    assert_includes result[:errors], "Input 'segments' must be an array for merge-videos nodes"
  end

  # mix-audio tests
  test "returns valid for mix-audio with video and audio inputs" do
    pipeline = create(:video_production_pipeline)
    video_node = create(:video_production_node, pipeline: pipeline)
    audio_node = create(:video_production_node, pipeline: pipeline)
    node = create(:video_production_node,
      pipeline: pipeline,
      type: 'mix-audio',
      inputs: {
        'video' => [video_node.uuid],
        'audio' => [audio_node.uuid]
      })

    result = VideoProduction::Node::ValidateInputs.(node)

    assert result[:valid], "Expected valid, got errors: #{result[:errors]}"
    assert_empty result[:errors]
  end

  test "returns invalid for mix-audio without video input" do
    node = build(:video_production_node,
      type: 'mix-audio',
      inputs: { 'audio' => ['some-uuid'] })

    result = VideoProduction::Node::ValidateInputs.(node)

    refute result[:valid]
    assert_includes result[:errors], "Input 'video' is required for mix-audio nodes"
  end

  test "returns invalid for mix-audio without audio input" do
    node = build(:video_production_node,
      type: 'mix-audio',
      inputs: { 'video' => ['some-uuid'] })

    result = VideoProduction::Node::ValidateInputs.(node)

    refute result[:valid]
    assert_includes result[:errors], "Input 'audio' is required for mix-audio nodes"
  end

  # compose-video tests
  test "returns valid for compose-video with background and overlay" do
    pipeline = create(:video_production_pipeline)
    bg_node = create(:video_production_node, pipeline: pipeline)
    overlay_node = create(:video_production_node, pipeline: pipeline)
    node = create(:video_production_node,
      pipeline: pipeline,
      type: 'compose-video',
      inputs: {
        'background' => [bg_node.uuid],
        'overlay' => [overlay_node.uuid]
      })

    result = VideoProduction::Node::ValidateInputs.(node)

    assert result[:valid], "Expected valid, got errors: #{result[:errors]}"
    assert_empty result[:errors]
  end

  # talking-head tests (optional inputs)
  test "returns valid for talking-head without script (optional)" do
    node = build(:video_production_node, type: 'talking-head', inputs: {})

    result = VideoProduction::Node::ValidateInputs.(node)

    assert result[:valid]
    assert_empty result[:errors]
  end

  test "returns valid for talking-head with script" do
    pipeline = create(:video_production_pipeline)
    script_node = create(:video_production_node, pipeline: pipeline, type: 'asset')
    node = create(:video_production_node,
      pipeline: pipeline,
      type: 'talking-head',
      inputs: { 'script' => [script_node.uuid] })

    result = VideoProduction::Node::ValidateInputs.(node)

    assert result[:valid], "Expected valid, got errors: #{result[:errors]}"
    assert_empty result[:errors]
  end

  # generate-animation tests (multiple optional inputs)
  test "returns valid for generate-animation with prompt and referenceImage" do
    pipeline = create(:video_production_pipeline)
    prompt_node = create(:video_production_node, pipeline: pipeline, type: 'asset')
    ref_node = create(:video_production_node, pipeline: pipeline, type: 'asset')
    node = create(:video_production_node,
      pipeline: pipeline,
      type: 'generate-animation',
      inputs: {
        'prompt' => [prompt_node.uuid],
        'referenceImage' => [ref_node.uuid]
      })

    result = VideoProduction::Node::ValidateInputs.(node)

    assert result[:valid], "Expected valid, got errors: #{result[:errors]}"
    assert_empty result[:errors]
  end

  test "returns valid for generate-animation with only prompt" do
    pipeline = create(:video_production_pipeline)
    prompt_node = create(:video_production_node, pipeline: pipeline, type: 'asset')
    node = create(:video_production_node,
      pipeline: pipeline,
      type: 'generate-animation',
      inputs: { 'prompt' => [prompt_node.uuid] })

    result = VideoProduction::Node::ValidateInputs.(node)

    assert result[:valid], "Expected valid, got errors: #{result[:errors]}"
    assert_empty result[:errors]
  end

  # Unexpected input slots
  test "returns invalid for node with unexpected input slot" do
    node = build(:video_production_node,
      type: 'asset',
      inputs: { 'unexpected_slot' => ['some-uuid'] })

    result = VideoProduction::Node::ValidateInputs.(node)

    refute result[:valid]
    assert_includes result[:errors], "Unexpected input slot(s) for asset nodes: unexpected_slot"
  end

  test "returns invalid for merge-videos with unexpected input slot" do
    pipeline = create(:video_production_pipeline)
    input1 = create(:video_production_node, pipeline: pipeline)
    input2 = create(:video_production_node, pipeline: pipeline)
    node = create(:video_production_node,
      pipeline: pipeline,
      type: 'merge-videos',
      inputs: {
        'segments' => [input1.uuid, input2.uuid],
        'unexpected' => ['foo']
      })

    result = VideoProduction::Node::ValidateInputs.(node)

    refute result[:valid]
    assert_includes result[:errors], "Unexpected input slot(s) for merge-videos nodes: unexpected"
  end

  # generate-voiceover tests
  test "returns valid for generate-voiceover without script (optional)" do
    node = build(:video_production_node, type: 'generate-voiceover', inputs: {})

    result = VideoProduction::Node::ValidateInputs.(node)

    assert result[:valid]
    assert_empty result[:errors]
  end

  # render-code tests
  test "returns valid for render-code without config (optional)" do
    node = build(:video_production_node, type: 'render-code', inputs: {})

    result = VideoProduction::Node::ValidateInputs.(node)

    assert result[:valid]
    assert_empty result[:errors]
  end
end
