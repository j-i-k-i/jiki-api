module V1
  module Auth
    class RegistrationsController < Devise::RegistrationsController
      respond_to :json

      def create
        super do |resource|
          User::Bootstrap.(resource) if resource.persisted?
        end
      end

      private
      def respond_with(resource, _opts = {})
        if resource.persisted?
          # Generate a refresh token for the newly registered user
          refresh_token = create_refresh_token(resource)

          render json: {
            user: user_data(resource),
            refresh_token: refresh_token.token
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

      def create_refresh_token(user)
        # Get device info from user agent (optional)
        aud = request.headers["User-Agent"]

        # Create a new refresh token with 30 day expiry
        user.refresh_tokens.create!(
          aud: aud,
          expires_at: 30.days.from_now
        )
      end
    end
  end
end
