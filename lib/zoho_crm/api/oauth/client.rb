# frozen_string_literal: true

# @!macro [new] returns_oauth_token
#   @return [ZohoCRM::API::OAuth::Token]

module ZohoCRM
  module API
    module OAuth
      class Client
        # @macro returns_oauth_token
        attr_reader :token

        # @param auth [Hash] Token attributes
        # @see ZohoCRM::API::OAuth::Token#initialize
        def initialize(auth = {})
          @token = ZohoCRM::API::OAuth::Token.new(auth)
        end

        # @return [String] URL of the Zoho authorization endpoint
        def authorize_url
          params = HTTP::URI.form_encode({
            client_id: ZohoCRM::API.config.client_id,
            scope: ZohoCRM::API.config.scopes.join(","),
            response_type: "code",
            redirect_uri: ZohoCRM::API.config.redirect_url,
            access_type: "offline",
            prompt: "consent",
          })

          "#{oauth_url}/auth?#{params}"
        end

        # Get an access_token/refresh_token pair
        #
        # @param grant_token [String]
        # @raise [ZohoCRM::API::OAuth::RequestError] if the request fails
        # @macro returns_oauth_token
        def create(grant_token:)
          params = {
            grant_type: "authorization_code",
            code: grant_token,
          }.merge(default_params)

          response = http.post(token_url, form: params)

          unless response.status.success?
            message = "Failed to generate and access token and a refresh token"
            raise ZohoCRM::API::OAuth::RequestError.new(message, response: response)
          end

          auth = response.parse

          token.access_token = auth["access_token"]
          token.refresh_token = auth["refresh_token"]
          token.expires_in_sec = auth["expires_in_sec"]
          token.expires_in = auth["expires_in"]
          token.token_type = auth["token_type"]
          token.api_domain = auth["api_domain"]
          token.refresh_time = Time.now.utc

          token
        end

        # Generate a new access token using the refresh token
        #
        # @raise [ZohoCRM::API::OAuth::Error] if the client is not authorized
        # @raise [ZohoCRM::API::OAuth::RequestError] if the request fails
        # @macro returns_oauth_token
        def refresh
          unless authorized?
            message = "The client needs to be authorized to generate a new access token"
            raise ZohoCRM::API::OAuth::Error.new(message, token: token)
          end

          params = {
            grant_type: "refresh_token",
            refresh_token: refresh_token,
          }.merge(default_params)

          response = http.post(token_url, form: params)

          unless response.status.success?
            message = "Failed to refresh the access token"
            raise ZohoCRM::API::OAuth::RequestError.new(message, response: response)
          end

          auth = response.parse

          token.access_token = auth["access_token"]
          token.expires_in_sec = auth["expires_in_sec"]
          token.expires_in = auth["expires_in"]
          token.token_type = auth["token_type"]
          token.api_domain = auth["api_domain"]
          token.refresh_time = Time.now.utc

          token
        end

        # Revoke the refresh token
        #
        # @raise [ZohoCRM::API::OAuth::RequestError] if the request fails
        # @macro returns_oauth_token
        def revoke
          params = {
            token: refresh_token,
          }.merge(default_params)

          response = http.post("#{token_url}/revoke", form: params)

          unless response.status.success?
            message = "Failed to revoke the refresh token"
            raise ZohoCRM::API::OAuth::RequestError.new(message, response: response)
          end

          token.refresh_token = nil

          token
        end

        # The OAuth client is authorized if the refresh token is neither `nil` nor empty
        #
        # @return [Boolean] Whether or not the OAuth client is authorized
        def authorized?
          !token.refresh_token.to_s.empty?
        end

        private

        def http
          @http ||= ZohoCRM::API.http_client
        end

        def oauth_url
          "#{ZohoCRM::API.config.accounts_url}/oauth/v2"
        end

        def token_url
          "#{oauth_url}/token"
        end

        def default_params
          {
            client_id: ZohoCRM::API.config.client_id,
            client_secret: ZohoCRM::API.config.client_secret,
            redirect_uri: ZohoCRM::API.config.redirect_url,
          }
        end
      end
    end
  end
end
