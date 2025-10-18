# frozen_string_literal: true

# rubocop:disable Rails/Output
module TypescriptGenerator
  class InputSchemaGenerator
    def initialize(output_dir)
      @output_dir = output_dir
    end

    def generate
      # Load all schema classes first
      schemas = load_schema_classes

      content = <<~TS
        /**
         * Video Production Node Types
         * Auto-generated from Rails schemas
         * DO NOT EDIT MANUALLY
         *
         * Generated at: #{Time.current.iso8601}
         * Source: app/commands/video_production/node/schemas/
         */

        #{generate_all_types(schemas)}
      TS

      write_file('src/nodes.ts', content)
      puts "✅ Generated src/nodes.ts"
    end

    private
    def generate_all_types(schemas)
      parts = []

      # Generate combined node types (inputs + provider config)
      parts << "// ============================================================================"
      parts << "// Video Production Node Types"
      parts << "// ============================================================================"
      parts << ""
      parts << schemas.map { |node_type, schema_class| generate_node_type(node_type, schema_class) }.join("\n\n")

      parts.join("\n")
    end

    def load_schema_classes
      # Map of node type to schema class
      schemas = {}

      # Dynamically load all schema files
      schema_dir = Rails.root.join('app', "commands", "video_production", "node", "schemas")
      Dir[schema_dir.join('*.rb')].each do |file|
        # Extract filename without extension
        filename = File.basename(file, '.rb')

        # Convert filename to class name (e.g., 'generate_talking_head' -> 'GenerateTalkingHead')
        class_name = filename.split('_').map(&:capitalize).join

        # Convert filename to node type (e.g., 'generate_talking_head' -> 'generate-talking-head')
        node_type = filename.tr('_', '-')

        # Require the file
        require file

        # Get the schema class
        schema_class = "VideoProduction::Node::Schemas::#{class_name}".constantize

        schemas[node_type] = schema_class
      end

      schemas
    end

    def generate_node_type(node_type, schema_class)
      type_name = node_type_to_type_name(node_type)
      inputs = schema_class::INPUTS

      # Check if PROVIDER_CONFIGS exists
      return nil unless schema_class.const_defined?(:PROVIDER_CONFIGS)

      provider_configs = schema_class::PROVIDER_CONFIGS
      return nil if provider_configs.empty?

      parts = []
      parts << "/** #{type_name} node type (inputs + provider-specific config) */"

      # Generate inputs object inline
      inputs_obj = generate_inputs_object(inputs)

      # Generate provider discriminated union
      provider_union = generate_provider_union(provider_configs)

      # Combine them with intersection (&)
      parts << "export type #{type_name}Node = {"
      parts << "  type: '#{node_type}';"
      parts << "  inputs: #{inputs_obj};"
      parts << "} & (#{provider_union});"

      parts.join("\n")
    end

    def generate_inputs_object(inputs)
      return "{}" if inputs.empty?

      lines = ["{"]

      inputs.each do |key, schema|
        # Determine TypeScript type based on schema
        case schema[:type]
        when :single
          ts_type = 'string'
        when :multiple
          ts_type = 'string[]'
        else
          ts_type = 'unknown'
        end

        # Add optional marker if not required
        optional_marker = schema[:required] ? '' : '?'

        lines << "    #{key}#{optional_marker}: #{ts_type};"
      end

      lines << "  }"
      lines.join("\n")
    end

    def generate_provider_union(provider_configs)
      union_parts = provider_configs.map do |provider_name, config_schema|
        config_obj = generate_config_object(config_schema)
        "\n  | { provider: '#{provider_name}'; config: #{config_obj} }"
      end

      union_parts.join
    end

    def generate_config_object(config_schema)
      return "{}" if config_schema.empty?

      lines = ["{"]

      config_schema.each do |key, field_schema|
        ts_type = generate_field_type(field_schema)
        optional_marker = field_schema[:required] ? '' : '?'

        lines << "      #{key}#{optional_marker}: #{ts_type};"
      end

      lines << "    }"
      lines.join("\n")
    end

    def generate_field_type(field_schema)
      case field_schema[:type]
      when :string
        base_type = 'string'
      when :integer
        base_type = 'number'
      when :boolean
        base_type = 'boolean'
      else
        base_type = 'unknown'
      end

      # If there are allowed values, create a union type
      if field_schema[:allowed_values]
        field_schema[:allowed_values].map { |v| "'#{v}'" }.join(' | ')
      else
        base_type
      end
    end

    def node_type_to_type_name(node_type)
      # Convert 'generate-talking-head' -> 'GenerateTalkingHead'
      node_type.split('-').map(&:capitalize).join
    end

    def write_file(filename, content)
      path = File.join(@output_dir, filename)
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, content)
    end
  end
end
# rubocop:enable Rails/Output
