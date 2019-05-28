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

    class APIRequestError < Error
      # @return [String] Zoho CRM API error code
      attr_reader :error_code

      # @return [Integer] HTTP status code
      attr_reader :status_code

      # @param message [String]
      # @param error_code [String] Zoho CRM API error code
      # @param status_code [Integer] HTTP status code
      def initialize(message = nil, error_code:, status_code:)
        @error_code = error_code
        @status_code = status_code
        message ||= "Zoho CRM API error -- code: #{error_code.inspect} - HTTP status code: #{status_code}"

        super(message)
      end
    end
  end
end
