module V1
  module Auth
    class SessionsController < Devise::SessionsController
      respond_to :json

      private
      def respond_with(resource, _opts = {})
        render json: {
          user: user_data(resource)
        }, status: :ok
      end

      def respond_with_error
        render json: {
          error: {
            type: "unauthorized",
            message: "Invalid email or password"
          }
        }, status: :unauthorized
      end

      def respond_to_on_destroy
        if current_user
          render json: {}, status: :no_content
        else
          render json: {
            error: {
              type: "unauthorized",
              message: "User has no active session"
            }
          }, status: :unauthorized
        end
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
