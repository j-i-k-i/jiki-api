class VideoProduction::Node::ValidateInputs
  include Mandate

  initialize_with :node

  class ValidationError < StandardError; end

  def call
    @errors = []
    @schema = VideoProduction::INPUT_SCHEMAS[node.type]

    validate_schema_exists!
    validate_unexpected_slots!
    validate_empty_schema!

    validate_slots!
    validate_node_references!

    { valid: errors.empty?, errors: errors }
  rescue ValidationError => e
    # Include any errors collected before the exception (e.g., unexpected slots)
    { valid: false, errors: errors + [e.message] }
  end

  private
  attr_reader :errors, :schema

  # Raise error if node type is unknown
  def validate_schema_exists!
    raise ValidationError, "Unknown node type: #{node.type}" unless schema
  end

  # Check for unexpected input slots (applies to all node types)
  def validate_unexpected_slots!
    return unless node.inputs.present?

    expected_slots = schema.keys.map(&:to_s)
    actual_slots = node.inputs.keys
    unexpected = actual_slots - expected_slots

    errors << "Unexpected input slot(s) for #{node.type} nodes: #{unexpected.join(', ')}" if unexpected.any?
  end

  # For empty schemas (asset nodes), raise if inputs present
  def validate_empty_schema!
    return unless schema.empty?

    return if node.inputs.blank? || node.inputs.empty?

    raise ValidationError, "#{node.type} nodes should not have inputs"
  end

  # Validate all slots according to schema rules
  def validate_slots!
    schema.each do |slot_name, rules|
      value = node.inputs&.dig(slot_name)

      validate_required!(slot_name, rules, value)
      next if value.nil? || value.empty?

      validate_type!(slot_name, rules, value)
      validate_min_items!(slot_name, rules, value)
    end
  end

  # Check if required slot is present
  def validate_required!(slot_name, rules, value)
    return unless rules[:required] && (value.nil? || value.empty?)

    errors << "Input '#{slot_name}' is required for #{node.type} nodes"
  end

  # Check if value is correct type
  def validate_type!(slot_name, rules, value)
    return unless rules[:type] == :array && !value.is_a?(Array)

    errors << "Input '#{slot_name}' must be an array for #{node.type} nodes"
  end

  # Check if array has minimum items
  def validate_min_items!(slot_name, rules, value)
    return unless rules[:min_items] && value.is_a?(Array) && value.length < rules[:min_items]

    errors << "Input '#{slot_name}' requires at least #{rules[:min_items]} item(s), got #{value.length}"
  end

  # Validate all node UUIDs exist in database (batch query to prevent N+1)
  def validate_node_references!
    return unless node.persisted?

    all_uuids = collect_all_uuids
    return if all_uuids.empty?

    invalid_uuids = find_invalid_uuids(all_uuids)
    return if invalid_uuids.empty?

    add_reference_errors!(invalid_uuids)
  end

  # Collect all UUIDs from all input slots
  def collect_all_uuids
    schema.each_key.flat_map do |slot_name|
      value = node.inputs&.dig(slot_name)
      value.is_a?(Array) ? value : []
    end.compact.uniq
  end

  # Find UUIDs that don't exist in the database
  def find_invalid_uuids(uuids)
    existing_uuids = VideoProduction::Node.where(
      pipeline_id: node.pipeline_id,
      uuid: uuids
    ).pluck(:uuid)

    uuids - existing_uuids
  end

  # Add error messages for slots with invalid UUID references
  def add_reference_errors!(invalid_uuids)
    schema.each_key do |slot_name|
      value = node.inputs&.dig(slot_name)
      next unless value.is_a?(Array)

      slot_invalid = value & invalid_uuids
      errors << "Input '#{slot_name}' references non-existent nodes: #{slot_invalid.join(', ')}" if slot_invalid.any?
    end
  end
end
