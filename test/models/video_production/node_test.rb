require "test_helper"

module VideoProduction
  class NodeTest < ActiveSupport::TestCase
    test "valid factory" do
      assert build(:video_production_node).valid?
    end

    test "validates uniqueness of uuid on update" do
      node1 = create(:video_production_node)
      node2 = create(:video_production_node)
      node2.uuid = node1.uuid

      refute node2.valid?(:update)
      assert_includes node2.errors[:uuid], "has already been taken"
    end

    test "validates presence of pipeline_id" do
      node = build(:video_production_node, pipeline: nil)
      refute node.valid?
      assert_includes node.errors[:pipeline], "must exist"
    end

    test "validates presence of title" do
      node = build(:video_production_node, title: nil)
      refute node.valid?
      assert_includes node.errors[:title], "can't be blank"
    end

    test "validates presence of type" do
      node = build(:video_production_node, type: nil)
      refute node.valid?
      assert_includes node.errors[:type], "can't be blank"
    end

    test "validates type inclusion" do
      valid_types = %w[asset generate-talking-head generate-animation generate-voiceover
                       render-code mix-audio merge-videos compose-video]

      valid_types.each do |valid_type|
        node = build(:video_production_node, type: valid_type)
        assert node.valid?, "#{valid_type} should be valid"
      end

      node = build(:video_production_node, type: 'invalid-type')
      refute node.valid?
      assert_includes node.errors[:type], "is not included in the list"
    end

    test "validates status inclusion" do
      %w[pending in_progress completed failed].each do |valid_status|
        node = build(:video_production_node, status: valid_status)
        assert node.valid?, "#{valid_status} should be valid"
      end

      node = build(:video_production_node, status: 'invalid')
      refute node.valid?
      assert_includes node.errors[:status], "is not included in the list"
    end

    test "generates uuid on creation" do
      node = create(:video_production_node)
      assert node.uuid.present?
      assert_match(/^[a-f0-9-]{36}$/, node.uuid) # UUID format
    end

    test "to_param returns uuid" do
      node = create(:video_production_node)
      assert_equal node.uuid, node.to_param
    end

    test "disable_sti! prevents STI behavior" do
      # Create nodes with different types - they should all be Node instances
      asset_node = create(:video_production_node, type: 'asset')
      merge_node = create(:video_production_node, :merge_videos)

      assert_instance_of VideoProduction::Node, asset_node
      assert_instance_of VideoProduction::Node, merge_node
    end

    test "belongs to pipeline" do
      pipeline = create(:video_production_pipeline)
      node = create(:video_production_node, pipeline: pipeline)

      assert_equal pipeline, node.pipeline
    end

    test "pending scope returns pending nodes" do
      pipeline = create(:video_production_pipeline)
      pending_node = create(:video_production_node, pipeline: pipeline, status: 'pending')
      create(:video_production_node, pipeline: pipeline, status: 'completed')

      assert_includes VideoProduction::Node.pending, pending_node
      assert_equal 1, VideoProduction::Node.pending.count
    end

    test "in_progress scope returns in_progress nodes" do
      pipeline = create(:video_production_pipeline)
      in_progress_node = create(:video_production_node, pipeline: pipeline, status: 'in_progress')
      create(:video_production_node, pipeline: pipeline, status: 'pending')

      assert_includes VideoProduction::Node.in_progress, in_progress_node
      assert_equal 1, VideoProduction::Node.in_progress.count
    end

    test "completed scope returns completed nodes" do
      pipeline = create(:video_production_pipeline)
      completed_node = create(:video_production_node, pipeline: pipeline, status: 'completed')
      create(:video_production_node, pipeline: pipeline, status: 'pending')

      assert_includes VideoProduction::Node.completed, completed_node
      assert_equal 1, VideoProduction::Node.completed.count
    end

    test "failed scope returns failed nodes" do
      pipeline = create(:video_production_pipeline)
      failed_node = create(:video_production_node, pipeline: pipeline, status: 'failed')
      create(:video_production_node, pipeline: pipeline, status: 'pending')

      assert_includes VideoProduction::Node.failed, failed_node
      assert_equal 1, VideoProduction::Node.failed.count
    end

    test "inputs_satisfied? returns true when no inputs" do
      node = create(:video_production_node, inputs: {})
      assert node.inputs_satisfied?
    end

    test "inputs_satisfied? returns true when inputs hash is empty arrays" do
      node = create(:video_production_node, inputs: { 'segments' => [] })
      assert node.inputs_satisfied?
    end

    test "inputs_satisfied? returns true when all input nodes completed" do
      pipeline = create(:video_production_pipeline)
      input1 = create(:video_production_node, pipeline: pipeline, status: 'completed')
      input2 = create(:video_production_node, pipeline: pipeline, status: 'completed')

      node = create(:video_production_node,
        pipeline: pipeline,
        inputs: { 'segments' => [input1.uuid, input2.uuid] })

      assert node.inputs_satisfied?
    end

    test "inputs_satisfied? returns false when any input pending" do
      pipeline = create(:video_production_pipeline)
      input1 = create(:video_production_node, pipeline: pipeline, status: 'completed')
      input2 = create(:video_production_node, pipeline: pipeline, status: 'pending')

      node = create(:video_production_node,
        pipeline: pipeline,
        inputs: { 'segments' => [input1.uuid, input2.uuid] })

      refute node.inputs_satisfied?
    end

    test "inputs_satisfied? returns false when any input failed" do
      pipeline = create(:video_production_pipeline)
      input1 = create(:video_production_node, pipeline: pipeline, status: 'completed')
      input2 = create(:video_production_node, pipeline: pipeline, status: 'failed')

      node = create(:video_production_node,
        pipeline: pipeline,
        inputs: { 'segments' => [input1.uuid, input2.uuid] })

      refute node.inputs_satisfied?
    end

    test "ready_to_execute? returns true when pending and is_valid" do
      pipeline = create(:video_production_pipeline)
      input = create(:video_production_node, pipeline: pipeline, status: 'completed')

      node = create(:video_production_node,
        pipeline: pipeline,
        status: 'pending',
        is_valid: true,
        inputs: { 'config' => [input.uuid] })

      assert node.ready_to_execute?
    end

    test "ready_to_execute? returns false when not pending" do
      node = create(:video_production_node, status: 'in_progress', inputs: {})
      refute node.ready_to_execute?
    end

    test "ready_to_execute? returns false when inputs not satisfied" do
      pipeline = create(:video_production_pipeline)
      input = create(:video_production_node, pipeline: pipeline, status: 'pending')

      node = create(:video_production_node,
        pipeline: pipeline,
        status: 'pending',
        inputs: { 'config' => [input.uuid] })

      refute node.ready_to_execute?
    end

    test "provider field works" do
      node = create(:video_production_node, :talking_head)
      assert_equal 'heygen', node.provider
    end

    test "metadata accessor works" do
      node = create(:video_production_node, :completed)
      assert node.metadata['completedAt'].present?
      assert_equal 0.05, node.metadata['cost']
    end

    test "output accessor works" do
      node = create(:video_production_node, :completed)
      assert_equal 'video', node.output['type']
      assert_equal 'output/test.mp4', node.output['s3Key']
    end
  end
end
