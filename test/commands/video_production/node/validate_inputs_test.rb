require "test_helper"

class VideoProduction::Node::ValidateInputsTest < ActiveSupport::TestCase
  test "returns valid for asset node with no inputs" do
    pipeline = create(:video_production_pipeline)

    assert VideoProduction::Node::ValidateInputs.('asset', {}, pipeline.id)
  end

  test "raises for asset node with inputs" do
    pipeline = create(:video_production_pipeline)

    error = assert_raises(VideoProductionBadInputsError) do
      VideoProduction::Node::ValidateInputs.('asset', { 'foo' => ['bar'] }, pipeline.id)
    end

    assert_includes error.message, "asset nodes should not have inputs"
  end

  test "raises for unknown node type" do
    pipeline = create(:video_production_pipeline)

    error = assert_raises(VideoProductionBadInputsError) do
      VideoProduction::Node::ValidateInputs.('unknown-type', {}, pipeline.id)
    end

    assert_includes error.message, "Unknown node type: unknown-type"
  end

  # merge-videos tests
  test "returns valid for merge-videos with valid segments" do
    pipeline = create(:video_production_pipeline)
    input1 = create(:video_production_node, pipeline: pipeline)
    input2 = create(:video_production_node, pipeline: pipeline)
    inputs = { 'segments' => [input1.uuid, input2.uuid] }

    assert VideoProduction::Node::ValidateInputs.('merge-videos', inputs, pipeline.id)
  end

  test "raises for merge-videos without segments" do
    pipeline = create(:video_production_pipeline)

    error = assert_raises(VideoProductionBadInputsError) do
      VideoProduction::Node::ValidateInputs.('merge-videos', {}, pipeline.id)
    end

    assert_includes error.message, "Input 'segments' is required for merge-videos nodes"
  end

  test "raises for merge-videos with only one segment" do
    pipeline = create(:video_production_pipeline)
    input1 = create(:video_production_node, pipeline: pipeline)
    inputs = { 'segments' => [input1.uuid] }

    error = assert_raises(VideoProductionBadInputsError) do
      VideoProduction::Node::ValidateInputs.('merge-videos', inputs, pipeline.id)
    end

    assert_includes error.message, "Input 'segments' requires at least 2 item(s), got 1"
  end

  test "raises for merge-videos with non-existent node UUIDs" do
    pipeline = create(:video_production_pipeline)
    inputs = { 'segments' => %w[fake-uuid-1 fake-uuid-2] }

    error = assert_raises(VideoProductionBadInputsError) do
      VideoProduction::Node::ValidateInputs.('merge-videos', inputs, pipeline.id)
    end

    assert_match(/Input 'segments' references non-existent nodes/, error.message)
  end

  test "raises for merge-videos with non-array segments" do
    pipeline = create(:video_production_pipeline)
    inputs = { 'segments' => 'not-an-array' }

    error = assert_raises(VideoProductionBadInputsError) do
      VideoProduction::Node::ValidateInputs.('merge-videos', inputs, pipeline.id)
    end

    assert_includes error.message, "Input 'segments' must be an array for merge-videos nodes"
  end

  # mix-audio tests
  test "returns valid for mix-audio with video and audio inputs" do
    pipeline = create(:video_production_pipeline)
    video_node = create(:video_production_node, pipeline: pipeline)
    audio_node = create(:video_production_node, pipeline: pipeline)
    inputs = {
      'video' => [video_node.uuid],
      'audio' => [audio_node.uuid]
    }

    assert VideoProduction::Node::ValidateInputs.('mix-audio', inputs, pipeline.id)
  end

  test "raises for mix-audio without video input" do
    pipeline = create(:video_production_pipeline)
    inputs = { 'audio' => ['some-uuid'] }

    error = assert_raises(VideoProductionBadInputsError) do
      VideoProduction::Node::ValidateInputs.('mix-audio', inputs, pipeline.id)
    end

    assert_includes error.message, "Input 'video' is required for mix-audio nodes"
  end

  test "raises for mix-audio without audio input" do
    pipeline = create(:video_production_pipeline)
    inputs = { 'video' => ['some-uuid'] }

    error = assert_raises(VideoProductionBadInputsError) do
      VideoProduction::Node::ValidateInputs.('mix-audio', inputs, pipeline.id)
    end

    assert_includes error.message, "Input 'audio' is required for mix-audio nodes"
  end

  # compose-video tests
  test "returns valid for compose-video with background and overlay" do
    pipeline = create(:video_production_pipeline)
    bg_node = create(:video_production_node, pipeline: pipeline)
    overlay_node = create(:video_production_node, pipeline: pipeline)
    inputs = {
      'background' => [bg_node.uuid],
      'overlay' => [overlay_node.uuid]
    }

    assert VideoProduction::Node::ValidateInputs.('compose-video', inputs, pipeline.id)
  end

  # talking-head tests (optional inputs)
  test "returns valid for talking-head without script (optional)" do
    pipeline = create(:video_production_pipeline)

    assert VideoProduction::Node::ValidateInputs.('talking-head', {}, pipeline.id)
  end

  test "returns valid for talking-head with script" do
    pipeline = create(:video_production_pipeline)
    script_node = create(:video_production_node, pipeline: pipeline, type: 'asset')
    inputs = { 'script' => [script_node.uuid] }

    assert VideoProduction::Node::ValidateInputs.('talking-head', inputs, pipeline.id)
  end

  # generate-animation tests (multiple optional inputs)
  test "returns valid for generate-animation with prompt and referenceImage" do
    pipeline = create(:video_production_pipeline)
    prompt_node = create(:video_production_node, pipeline: pipeline, type: 'asset')
    ref_node = create(:video_production_node, pipeline: pipeline, type: 'asset')
    inputs = {
      'prompt' => [prompt_node.uuid],
      'referenceImage' => [ref_node.uuid]
    }

    assert VideoProduction::Node::ValidateInputs.('generate-animation', inputs, pipeline.id)
  end

  test "returns valid for generate-animation with only prompt" do
    pipeline = create(:video_production_pipeline)
    prompt_node = create(:video_production_node, pipeline: pipeline, type: 'asset')
    inputs = { 'prompt' => [prompt_node.uuid] }

    assert VideoProduction::Node::ValidateInputs.('generate-animation', inputs, pipeline.id)
  end

  # Unexpected input slots
  test "raises for node with unexpected input slot" do
    pipeline = create(:video_production_pipeline)
    inputs = { 'unexpected_slot' => ['some-uuid'] }

    error = assert_raises(VideoProductionBadInputsError) do
      VideoProduction::Node::ValidateInputs.('asset', inputs, pipeline.id)
    end

    assert_includes error.message, "Unexpected input slot(s) for asset nodes: unexpected_slot"
  end

  test "raises for merge-videos with unexpected input slot" do
    pipeline = create(:video_production_pipeline)
    input1 = create(:video_production_node, pipeline: pipeline)
    input2 = create(:video_production_node, pipeline: pipeline)
    inputs = {
      'segments' => [input1.uuid, input2.uuid],
      'unexpected' => ['foo']
    }

    error = assert_raises(VideoProductionBadInputsError) do
      VideoProduction::Node::ValidateInputs.('merge-videos', inputs, pipeline.id)
    end

    assert_includes error.message, "Unexpected input slot(s) for merge-videos nodes: unexpected"
  end

  # generate-voiceover tests
  test "returns valid for generate-voiceover without script (optional)" do
    pipeline = create(:video_production_pipeline)

    assert VideoProduction::Node::ValidateInputs.('generate-voiceover', {}, pipeline.id)
  end

  # render-code tests
  test "returns valid for render-code without config (optional)" do
    pipeline = create(:video_production_pipeline)

    assert VideoProduction::Node::ValidateInputs.('render-code', {}, pipeline.id)
  end
end
