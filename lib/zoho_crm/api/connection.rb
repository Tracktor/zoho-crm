# frozen_string_literal: true

# @!macro [new] raises_errors
#   @raise [ZohoCRM::API::OAuth::Error] if the OAuth client is not authorized
#   @raise [ZohoCRM::API::HTTPRequestError] if the response's status has an error code
#   @raise [ZohoCRM::API::HTTPTimeoutError] if the request timed out
#   @raise [ZohoCRM::API::HTTPError] if the request encounters a connection error

# @!macro [new] request_params_without_body
#   @param headers [Hash{String => String}] HTTP Headers
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
      # @macro raises_errors
      # @macro returns_http_response
      def get(uri, headers: {}, query: {})
        request(:get, uri, headers: headers, params: query)
      end

      # @param uri [String] API endpoint
      # @macro request_params
      # @macro raises_errors
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
        "#{oauth_client.config.base_url}/#{uri}"
      end

      # @api private
      # @param verb [Symbol] HTTP verb
      # @param uri [String] API endpoint
      # @param options Request options
      # @option options [Hash{String => String}] :headers HTTP Headers
      # @option options [Hash] :params query string params
      # @option options [Hash] :json JSON body
      # @macro raises_errors
      # @macro returns_http_response
      def request(verb, uri, **options)
        if oauth_client.authorized?
          oauth_client.refresh if oauth_client.token.expired?
        else
          raise ZohoCRM::API::OAuth::Error.new("The OAuth client is not authorized")
        end

        response = http.request(verb, build_url(uri), options)

        if response.status.success?
          response
        else
          raise ZohoCRM::API::HTTPRequestError.new(response: response)
        end
      rescue HTTP::ConnectionError
        raise ZohoCRM::API::HTTPError
      rescue HTTP::TimeoutError
        raise ZohoCRM::API::HTTPTimeoutError
      end

      # @api private
      def http
        @http ||= ZohoCRM::API.http_client.headers({
          "Authorization" => "Zoho-oauthtoken #{oauth_client.token.access_token}",
        })
      end
    end
  end
end
