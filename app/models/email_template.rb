class EmailTemplate < ApplicationRecord
  enum :template_type, { level_completion: 0 }

  validates :template_type, presence: true
  validates :locale, presence: true
  validates :subject, presence: true
  validates :body_mjml, presence: true
  validates :body_text, presence: true
  validates :template_type, uniqueness: { scope: %i[key locale] }

  # Generic finder for any template type, key, and locale
  # @param template_type [Symbol] The type of template (e.g., :level_completion)
  # @param key [String] The template key (e.g., level slug)
  # @param locale [String] The locale (e.g., "en", "hu")
  # @return [EmailTemplate, nil] The template if found, nil otherwise
  def self.find_for(template_type, key, locale)
    find_by(template_type:, key:, locale:)
  end

  # Scope to find level completion templates
  scope :for_level_completion, lambda { |level_slug, locale|
    where(template_type: :level_completion, key: level_slug, locale:)
  }

  # Find a template for level completion, returning nil if not found
  def self.find_for_level_completion(level_slug, locale)
    find_for(:level_completion, level_slug, locale)
  end
end
