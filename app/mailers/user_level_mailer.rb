require 'mrml'

class UserLevelMailer < ApplicationMailer
  # Sends a level completion email to a user
  #
  # @param user_level [UserLevel] The user_level record that was completed
  def completed(user_level)
    @user_level = user_level
    @user = user_level.user
    @level = user_level.level

    # Find the email template for this level and locale
    template = EmailTemplate.find_for_level_completion(@level.slug, @user.locale)
    return unless template

    # Render the template with Liquid
    liquid_context = {
      'user' => UserDrop.new(@user),
      'level' => LevelDrop.new(@level)
    }

    # Render MJML body with Liquid
    mjml_with_variables = Liquid::Template.parse(template.body_mjml).render(liquid_context)

    # Convert HAML MJML to pure MJML, then compile to HTML using mrml gem
    haml_engine = Haml::Template.new { mjml_with_variables }
    mjml_content = haml_engine.render
    html_body = begin
      require 'mrml' unless defined?(::Mrml)
      ::Mrml.to_html(mjml_content)[:html]
    end

    # Render text body with Liquid
    text_body = Liquid::Template.parse(template.body_text).render(liquid_context)

    # Render subject with Liquid
    subject = Liquid::Template.parse(template.subject).render(liquid_context)

    with_locale(@user) do
      mail(
        to: @user.email,
        subject:
      ) do |format|
        format.html { render html: html_body.html_safe }
        format.text { render plain: text_body }
      end
    end
  end
end
