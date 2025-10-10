module V1
  module Admin
    class EmailTemplatesController < BaseController
      before_action :set_email_template, only: %i[show update destroy]

      def index
        email_templates = EmailTemplate.all
        render json: {
          email_templates: SerializeEmailTemplates.(email_templates)
        }
      end

      def show
        render json: {
          email_template: SerializeEmailTemplate.(@email_template)
        }
      end

      def update
        email_template = EmailTemplate::Update.(@email_template, email_template_params)
        render json: {
          email_template: SerializeEmailTemplate.(email_template)
        }
      end

      def destroy
        @email_template.destroy!
        head :no_content
      end

      private
      def set_email_template
        @email_template = EmailTemplate.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: {
          error: {
            type: "not_found",
            message: "Email template not found"
          }
        }, status: :not_found
      end

      def email_template_params
        params.require(:email_template).permit(:subject, :body_mjml, :body_text)
      end
    end
  end
end
