class EmailTemplate::TranslateToLocale
  include Mandate

  initialize_with :source_template, :target_locale

  def call
    validate!

    # Delete existing template if present (upsert pattern)
    EmailTemplate.find_for(source_template.type, source_template.slug, target_locale)&.destroy

    # Create placeholder template
    target_template = EmailTemplate.create!(
      type: source_template.type,
      slug: source_template.slug,
      locale: target_locale,
      subject: '', # Will be filled by LLM callback
      body_mjml: '',
      body_text: ''
    )

    # Send to LLM proxy for translation
    LLM::Exec.(
      :gemini,
      :flash,
      translation_prompt,
      'email_translation',
      email_template_id: target_template.id
    )

    target_template
  end

  private
  def validate!
    raise ArgumentError, "Source template must be in English (en)" unless source_template.locale == "en"
    raise ArgumentError, "Target locale cannot be English (en)" if target_locale == "en"
    raise ArgumentError, "Target locale not supported" unless supported_locales.include?(target_locale)
  end

  memoize
  def supported_locales
    (I18n::SUPPORTED_LOCALES + I18n::WIP_LOCALES).map(&:to_s)
  end

  memoize
  def locale_display_name
    I18n.t("locales.#{target_locale}", default: target_locale.upcase)
  end

  memoize
  def translation_prompt
    <<~PROMPT
      You are a professional localization expert specializing in educational content translation.

      Task: Translate an email template from English to #{locale_display_name} (#{target_locale}).

      Context:
      - Template Type: #{source_template.type}
      - Template Slug: #{source_template.slug}
      - Target Language: #{locale_display_name} (#{target_locale})

      Translation Rules:
      1. Maintain the original meaning, tone, and intent
      2. Preserve approximate message length (don't make it significantly longer or shorter)
      3. DO NOT translate MJML tags or HTML/MJML attributes (like <mj-text>, <mj-button>, href, etc.)
      4. DO translate the content within MJML tags
      5. Preserve variable placeholders exactly as they appear (e.g., %<name>s, %<level_title>s)
      6. Maintain formatting markers like line breaks and emphasis
      7. Adapt cultural references appropriately for the target locale
      8. Use natural, native-sounding language for #{locale_display_name}

      Source Content to Translate:

      Subject:
      #{source_template.subject}

      Body (MJML):
      #{source_template.body_mjml}

      Body (Plain Text):
      #{source_template.body_text}

      Required Output:
      Return ONLY a valid JSON object with these three fields (no additional text or markdown):
      {
        "subject": "translated subject",
        "body_mjml": "translated MJML body with preserved tags",
        "body_text": "translated plain text body"
      }
    PROMPT
  end
end
