class VideoProduction::Node::ValidateConfig
  include Mandate

  initialize_with :node, :schema, :provider

  def call
    return {} if schema.blank?

    # Get provider-specific config schema
    provider_configs = begin
      schema.const_get(:PROVIDER_CONFIGS)
    rescue StandardError
      {}
    end
    return {} if provider_configs.blank?

    # Get the config schema for this provider
    provider_schema = provider_configs[provider]
    return {} if provider_schema.blank?

    errors = {}
    errors.merge!(validate_each_config_key(provider_schema))
    errors
  end

  private
  def validate_each_config_key(provider_schema)
    errors = {}

    provider_schema.each do |key_name, rules|
      value = node.config&.dig(key_name)

      # Validate required
      if rules[:required] && value.nil?
        errors[key_name.to_sym] = "is required for #{node.type} nodes"
        next
      end

      # Skip further validation if value is nil and not required
      next if value.nil?

      # Validate type
      if rules[:type]
        expected_type = rules[:type]
        case expected_type
        when :string then valid = value.is_a?(String)
        when :integer then valid = value.is_a?(Integer)
        when :boolean then valid = [true, false].include?(value)
        when :array then valid = value.is_a?(Array)
        when :hash then valid = value.is_a?(Hash)
        else valid = true
        end

        unless valid
          errors[key_name.to_sym] = "must be a #{expected_type}"
          next
        end
      end

      # Validate allowed_values
      if rules[:allowed_values] && !rules[:allowed_values].include?(value)
        errors[key_name.to_sym] = "must be one of: #{rules[:allowed_values].join(', ')}"
      end
    end

    errors
  end
end
