# Configure JSON parsing to use symbolized keys for consistency
# This allows us to use symbols throughout our codebase when working with JSON data
# The JSON gem is now faster than Oj for parsing as of 2025, so we use the standard library

class JSONWithIndifferentAccess
  def self.load(value)
    return {} if value.nil?
    return value.deep_symbolize_keys if value.is_a?(Hash)

    JSON.parse(value, symbolize_names: true)
  end

  def self.dump(obj)
    JSON.generate(obj)
  end
end
