class VideoProduction::Node::ValidateInputs
  include Mandate

  initialize_with :node

  def call
    errors = []

    # Get schema for this node type
    schema = VideoProduction::INPUT_SCHEMAS[node.type]

    if schema.nil?
      return {
        valid: false,
        errors: ["Unknown node type: #{node.type}"]
      }
    end

    # Check for unexpected input slots first (applies to all node types including asset)
    if node.inputs.present?
      expected_slots = schema.keys.map(&:to_s)
      actual_slots = node.inputs.keys
      unexpected = actual_slots - expected_slots

      errors << "Unexpected input slot(s) for #{node.type} nodes: #{unexpected.join(', ')}" if unexpected.any?
    end

    # If schema is empty (like asset nodes), inputs should be empty
    if schema.empty?
      errors << "#{node.type} nodes should not have inputs" unless node.inputs.blank? || node.inputs.empty?

      return { valid: errors.empty?, errors: errors }
    end

    # Collect all UUIDs to validate in a single query
    all_uuids_to_validate = []

    # Validate each defined slot in the schema
    schema.each do |slot_name, rules|
      value = node.inputs&.dig(slot_name)

      # Check required
      if rules[:required] && (value.nil? || value.empty?)
        errors << "Input '#{slot_name}' is required for #{node.type} nodes"
        next # Skip further validation for this slot if it's missing
      end

      # Skip further validation if value is nil/empty and not required
      next if value.nil? || value.empty?

      # Check type
      if rules[:type] == :array && !value.is_a?(Array)
        errors << "Input '#{slot_name}' must be an array for #{node.type} nodes"
        next
      end

      # Check min_items
      if rules[:min_items] && value.is_a?(Array) && value.length < rules[:min_items]
        errors << "Input '#{slot_name}' requires at least #{rules[:min_items]} item(s), got #{value.length}"
      end

      # Collect UUIDs for batch validation
      all_uuids_to_validate.concat(value) if value.is_a?(Array) && node.persisted?
    end

    # Validate all UUIDs in a single query (prevents N+1)
    if all_uuids_to_validate.any?
      invalid_uuids = validate_node_references(all_uuids_to_validate.uniq)

      if invalid_uuids.any?
        # Find which slots had invalid UUIDs
        schema.each_key do |slot_name|
          value = node.inputs&.dig(slot_name)
          next unless value.is_a?(Array)

          slot_invalid = value & invalid_uuids
          errors << "Input '#{slot_name}' references non-existent nodes: #{slot_invalid.join(', ')}" if slot_invalid.any?
        end
      end
    end

    { valid: errors.empty?, errors: errors }
  end

  private
  def validate_node_references(uuids)
    return [] if uuids.empty?

    existing_uuids = VideoProduction::Node.where(
      pipeline_id: node.pipeline_id,
      uuid: uuids
    ).pluck(:uuid)

    uuids - existing_uuids
  end
end
