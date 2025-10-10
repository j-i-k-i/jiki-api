module SPI
  class LLMResponsesController < SPI::BaseController
    # Callback for email translation completion
    def email_translation
      template = EmailTemplate.find(params[:email_template_id])

      # Parse the LLM response as JSON
      llm_response = JSON.parse(params[:resp], symbolize_names: true)

      # Update the template with translated content
      template.update!(
        subject: llm_response[:subject],
        body_mjml: llm_response[:body_mjml],
        body_text: llm_response[:body_text]
      )

      Rails.logger.info "Email template #{template.id} translated successfully"

      head :ok
    rescue ActiveRecord::RecordNotFound => e
      Rails.logger.error "Email template not found: #{e.message}"
      render json: { error: 'Email template not found' }, status: :not_found
    rescue JSON::ParserError => e
      Rails.logger.error "Invalid JSON response: #{e.message}"
      render json: { error: 'Invalid JSON response' }, status: :unprocessable_entity
    rescue StandardError => e
      Rails.logger.error "Email translation callback failed: #{e.message}"
      render json: { error: 'Internal server error' }, status: :internal_server_error
    end

    # Callback for rate limiting errors
    def rate_limited
      # TODO: Implement retry logic
      # For now, just log the error
      Rails.logger.warn "LLM rate limit hit: #{params[:error]}"
      Rails.logger.warn "Retry after: #{params[:retry_after]} seconds"
      Rails.logger.warn "Original params: #{params[:original_params]}"

      # Future enhancement: Queue for retry after the specified delay
      # EmailTemplate::TranslateToLocale.defer_with_delay(
      #   params[:original_params][:email_template_id],
      #   delay: params[:retry_after].to_i.seconds
      # )

      head :ok
    end

    # Callback for general errors
    def errored
      # TODO: Implement error handling and logging
      # For now, just log the error
      Rails.logger.error "LLM request failed: #{params[:error]}"
      Rails.logger.error "Error type: #{params[:error_type]}"
      Rails.logger.error "Original params: #{params[:original_params]}"

      # Future enhancement: Store error in database, notify admins, etc.
      # ErrorLog.create!(
      #   error_type: 'llm_failure',
      #   message: params[:error],
      #   metadata: params[:original_params]
      # )

      head :ok
    end
  end
end
