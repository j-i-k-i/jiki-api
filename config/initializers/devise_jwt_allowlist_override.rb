# frozen_string_literal: true

# Override Devise::JWT::RevocationStrategies::Allowlist to use our custom naming
# Instead of the default :allowlisted_jwts association, we use :jwt_tokens
#
# This allows us to use semantic naming (User::JwtToken, user.jwt_tokens)
# instead of the default Allowlist naming convention.

module Devise
  module JWT
    module RevocationStrategies
      module Allowlist
        # Include this module in your user model to enable Allowlist revocation strategy
        # with custom association name
        def self.included(base)
          base.class_eval do
            # Create the default allowlisted_jwts association that Devise JWT expects
            has_many :allowlisted_jwts,
              class_name: "#{base.name}::JwtToken",
              foreign_key: :user_id,
              dependent: :destroy

            # Alias jwt_tokens to allowlisted_jwts for cleaner semantics
            # Now user.jwt_tokens works as an alias to user.allowlisted_jwts
            alias_method :jwt_tokens, :allowlisted_jwts unless method_defined?(:jwt_tokens)
          end
        end

        # Called when a JWT token is dispatched (on login/signup)
        # Creates a new record in user_jwt_tokens table
        def on_jwt_dispatch(_token, payload)
          allowlisted_jwts.create!(
            jti: payload["jti"],
            aud: payload["aud"],
            expires_at: Time.zone.at(payload["exp"].to_i)
          )
        end

        # Called on each authenticated request to check if token is valid
        # Returns true if the token's jti exists in the allowlist
        def jwt_revoked?(payload, _user)
          !allowlisted_jwts.exists?(jti: payload["jti"])
        end

        # Called when a JWT token is revoked (on logout)
        # Deletes the record from user_jwt_tokens table
        def revoke_jwt(payload, _user)
          allowlisted_jwts.find_by(jti: payload["jti"])&.destroy
        end
      end
    end
  end
end
