# frozen_string_literal: true

# @!macro [new] raises_authorization_errors
#   @raise [ZohoCRM::API::OAuth::Error] if the OAuth client is not authorized

# @!macro [new] raises_response_errors
#   @raise [ZohoCRM::API::HTTPRequestError,
#           ZohoCRM::API::UnauthorizedAPIRequestError,
#           ZohoCRM::API::APIRequestError] if the response's status has an error code

# @!macro [new] request_params_without_body
#   @param headers [Hash<String=>String>] HTTP Headers
#   @param query [Hash] query string params

# @!macro [new] request_params
#   @macro request_params_without_body
#   @param body [Hash] JSON body

# @!macro [new] returns_http_response
#   @return [HTTP::Response]

module ZohoCRM
  module API
    class Connection
      # @api private
      # @return [ZohoCRM::API::OAuth]
      attr_reader :oauth_client

      # @param oauth_client [ZohoCRM::API::OAuth]
      def initialize(oauth_client)
        @oauth_client = oauth_client
      end

      # @!group HTTP Requests

      # @param uri [String] API endpoint
      # @macro request_params_without_body
      # @macro raises_authorization_errors
      # @macro raises_response_errors
      # @macro returns_http_response
      def get(uri, headers: {}, query: {})
        request(:get, uri, headers: headers, params: query)
      end

      # @param uri [String] API endpoint
      # @macro request_params
      # @macro raises_authorization_errors
      # @macro raises_response_errors
      # @macro returns_http_response
      def post(uri, headers: {}, query: {}, body: {})
        request(:post, uri, headers: headers, params: query, json: body)
      end

      # (see #post)
      def put(uri, headers: {}, query: {}, body: {})
        request(:put, uri, headers: headers, params: query, json: body)
      end

      # (see #post)
      def patch(uri, headers: {}, query: {}, body: {})
        request(:patch, uri, headers: headers, params: query, json: body)
      end

      # (see #get)
      def delete(uri, headers: {}, query: {})
        request(:delete, uri, headers: headers, params: query)
      end

      # @!endgroup

      # @api private
      # @param uri [String] API endpoint
      # @return [String] API request URL
      def build_url(uri)
        "#{ZohoCRM::API.config.base_url}/#{uri}"
      end

      # @api private
      # @param verb [Symbol] HTTP verb
      # @param uri [String] API endpoint
      # @param options Request options
      # @option options [Hash<String=>String>] :headers HTTP Headers
      # @option options [Hash] :params query string params
      # @option options [Hash] :json JSON body
      # @macro raises_authorization_errors
      # @macro raises_response_errors
      # @macro returns_http_response
      def request(verb, uri, **options)
        check_authorization!

        response = http.request(verb, build_url(uri), options)

        check_response!(response)

        response
      end

      # @api private
      def http
        @http ||= ZohoCRM::API.http_client.headers({
          "Authorization" => "Zoho-oauthtoken #{oauth_client.token.access_token}",
        })
      end

      private

      # Checks that the OAuth client is authorized and refresh the auth token if it's expired.
      #
      # @macro raises_authorization_errors
      # @return [void]
      # @see ZohoCRM::API::OAuth::Client#authorized?
      def check_authorization!
        unless oauth_client.authorized?
          raise ZohoCRM::API::OAuth::Error.new("The OAuth client is not authorized")
        end

        if oauth_client.token.expired?
          oauth_client.refresh
        end
      end

      # @param response [HTTP::Response]
      # @macro raises_response_errors
      # @return [void]
      def check_response!(response)
        return if response.status.success?

        status_code = ZohoCRM::API::StatusCodes[response.status.code]
        error =
          if status_code.nil?
            ZohoCRM::API::HTTPRequestError.new(response: response)
          elsif response.status.code == ZohoCRM::API::StatusCodes.authorization_error
            ZohoCRM::API::UnauthorizedAPIRequestError.new(response: response)
          else
            ZohoCRM::API::APIRequestError.new(response: response)
          end

        raise error
      end
    end
  end
end
