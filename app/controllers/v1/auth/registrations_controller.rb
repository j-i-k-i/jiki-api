module V1
  module Auth
    class RegistrationsController < Devise::RegistrationsController
      respond_to :json

      private
      def respond_with(resource, _opts = {})
        if resource.persisted?
          render json: {
            user: user_data(resource)
          }, status: :created
        else
          render json: {
            error: {
              type: "validation_error",
              message: "Validation failed",
              errors: resource.errors.messages
            }
          }, status: :unprocessable_entity
        end
      end

      def sign_up_params
        params.require(:user).permit(:email, :password, :password_confirmation, :name)
      end

      def user_data(user)
        {
          id: user.id,
          email: user.email,
          name: user.name,
          created_at: user.created_at
        }
      end
    end
  end
end
