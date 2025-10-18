require "test_helper"

class VideoProduction::Node::ValidateConfigTest < ActiveSupport::TestCase
  # Test schema class for custom validation tests
  class TestSchema
    INPUTS = {}.freeze
    PROVIDER_CONFIGS = {
      'test-provider' => {
        'provider' => {
          type: :string,
          required: true
        },
        'apiKey' => {
          type: :string,
          required: true
        },
        'width' => {
          type: :integer,
          required: true
        },
        'volume' => {
          type: :integer,
          required: false
        },
        'transparentBackground' => {
          type: :boolean,
          required: true
        },
        'layers' => {
          type: :array,
          required: true
        },
        'inputProps' => {
          type: :hash,
          required: true
        }
      },
      'simple-provider' => {
        'provider' => {
          type: :string,
          required: true,
          allowed_values: %w[heygen remotion ffmpeg]
        }
      }
    }.freeze
  end
  test "returns empty hash when config schema is nil" do
    pipeline = create(:video_production_pipeline)
    node = build(:video_production_node, pipeline:, type: 'asset', provider: 'direct', config: {})

    result = VideoProduction::Node::ValidateConfig.(node, nil, 'direct')

    assert_empty result
  end

  test "returns empty hash when provider has no config" do
    pipeline = create(:video_production_pipeline)
    node = build(:video_production_node, pipeline:, type: 'asset', provider: 'direct', config: {})

    schema = VideoProduction::Node::Schemas::Asset
    result = VideoProduction::Node::ValidateConfig.(node, schema, 'direct')

    assert_empty result
  end

  test "validates provider-specific config correctly" do
    pipeline = create(:video_production_pipeline)
    node = build(:video_production_node,
      pipeline:,
      type: 'generate-talking-head',
      provider: 'heygen',
      config: {
        'avatar_id' => 'avatar-1',
        'voice_id' => 'voice-1'
      })

    schema = VideoProduction::Node::Schemas::GenerateTalkingHead
    result = VideoProduction::Node::ValidateConfig.(node, schema, 'heygen')

    assert_empty result
  end

  test "returns error when required config key is missing" do
    pipeline = create(:video_production_pipeline)
    node = build(:video_production_node,
      pipeline:,
      type: 'test-node',
      provider: 'test-provider',
      config: {}) # missing required keys

    result = VideoProduction::Node::ValidateConfig.(node, TestSchema, 'test-provider')

    assert result.key?(:provider)
    assert_equal "is required for test-node nodes", result[:provider]
  end

  test "returns error for invalid config value type - string" do
    pipeline = create(:video_production_pipeline)
    node = build(:video_production_node,
      pipeline:,
      type: 'test-node',
      provider: 'test-provider',
      config: {
        'provider' => 123 # should be string
      })

    result = VideoProduction::Node::ValidateConfig.(node, TestSchema, 'test-provider')

    assert result.key?(:provider)
    assert_equal "must be a string", result[:provider]
  end

  test "returns error for invalid array type" do
    pipeline = create(:video_production_pipeline)
    node = build(:video_production_node,
      pipeline:,
      type: 'test-node',
      provider: 'test-provider',
      config: {
        'layers' => 'not-an-array' # should be array
      })

    result = VideoProduction::Node::ValidateConfig.(node, TestSchema, 'test-provider')

    assert result.key?(:layers)
    assert_equal "must be a array", result[:layers]
  end

  test "returns error for invalid hash type" do
    pipeline = create(:video_production_pipeline)
    node = build(:video_production_node,
      pipeline:,
      type: 'test-node',
      provider: 'test-provider',
      config: {
        'inputProps' => 'not-a-hash' # should be hash
      })

    result = VideoProduction::Node::ValidateConfig.(node, TestSchema, 'test-provider')

    assert result.key?(:inputProps)
    assert_equal "must be a hash", result[:inputProps]
  end

  test "validates correctly and returns early on first error" do
    pipeline = create(:video_production_pipeline)
    node = build(:video_production_node,
      pipeline:,
      type: 'test-node',
      provider: 'test-provider',
      config: {
        'provider' => 123 # invalid type
      })

    result = VideoProduction::Node::ValidateConfig.(node, TestSchema, 'test-provider')

    # Should return first error (provider type)
    assert result.key?(:provider)
    assert_equal "must be a string", result[:provider]
  end

  test "allows optional config keys to be missing" do
    pipeline = create(:video_production_pipeline)
    node = build(:video_production_node,
      pipeline:,
      type: 'test-node',
      provider: 'test-provider',
      config: {
        'provider' => 'ffmpeg',
        'apiKey' => 'test-key',
        'width' => 1920,
        'transparentBackground' => true,
        'layers' => [],
        'inputProps' => {}
        # volume is optional, not included
      })

    result = VideoProduction::Node::ValidateConfig.(node, TestSchema, 'test-provider')

    assert_empty result
  end

  test "validates boolean type correctly" do
    pipeline = create(:video_production_pipeline)
    node = build(:video_production_node,
      pipeline:,
      type: 'test-node',
      provider: 'test-provider',
      config: {
        'transparentBackground' => 'yes' # should be boolean
      })

    result = VideoProduction::Node::ValidateConfig.(node, TestSchema, 'test-provider')

    assert result.key?(:transparentBackground)
    assert_equal "must be a boolean", result[:transparentBackground]
  end

  test "validates integer type correctly" do
    pipeline = create(:video_production_pipeline)
    node = build(:video_production_node,
      pipeline:,
      type: 'test-node',
      provider: 'test-provider',
      config: {
        'width' => '1920' # should be integer
      })

    result = VideoProduction::Node::ValidateConfig.(node, TestSchema, 'test-provider')

    assert result.key?(:width)
    assert_equal "must be a integer", result[:width]
  end

  test "validates allowed_values constraint" do
    pipeline = create(:video_production_pipeline)
    node = build(:video_production_node,
      pipeline:,
      type: 'test-node',
      provider: 'simple-provider',
      config: {
        'provider' => 'invalid-provider'
      })

    result = VideoProduction::Node::ValidateConfig.(node, TestSchema, 'simple-provider')

    assert result.key?(:provider)
    assert_equal "must be one of: heygen, remotion, ffmpeg", result[:provider]
  end
end
