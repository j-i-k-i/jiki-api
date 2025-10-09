class EmailTemplate < ApplicationRecord
  enum :template_type, { level_completion: 0 }

  validates :template_type, presence: true
  validates :locale, presence: true
  validates :subject, presence: true
  validates :body_mjml, presence: true
  validates :body_text, presence: true
  validates :template_type, uniqueness: { scope: %i[key locale] }

  # Scope to find level completion templates
  scope :for_level_completion, lambda { |level_slug, locale|
    where(template_type: :level_completion, key: level_slug, locale:)
  }

  # Find a template for level completion, returning nil if not found
  def self.find_for_level_completion(level_slug, locale)
    for_level_completion(level_slug, locale).first
  end
end
