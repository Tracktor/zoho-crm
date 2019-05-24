# frozen_string_literal: true

module ZohoCRM
  module API
    class Error < StandardError
    end

    class ConfigurationError < Error
    end

    class HTTPError < Error
    end

    class HTTPTimeoutError < HTTPError
    end

    class HTTPRequestError < HTTPError
      # @return [HTTP::Response]
      attr_reader :response

      # @param message [String]
      # @param response [HTTP::Response]
      def initialize(message = nil, response:)
        @response = response
        super(message || response.status.reason)
      end
    end

    class APIRequestError < HTTPRequestError
      # @return [String]
      attr_reader :code

      # (see HTTPRequestError#initialize)
      def initialize(message = nil, response:)
        body = response.parse

        # This should NOT happen (it would mean that the API request actually succeeded)
        if body.is_a?(Hash)
          @code = body["code"]
          message = body["message"]
        end

        super(message, response: response)
      end
    end
  end
end
