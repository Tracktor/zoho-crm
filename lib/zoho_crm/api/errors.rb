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

      # @return [Hash] Details of the error
      attr_reader :details

      # @return [Integer] HTTP status code
      attr_reader :status_code

      # @return [HTTP::Response]
      attr_reader :response

      # @param message [String]
      # @param error_code [String] Zoho CRM API error code
      # @param details [Hash] Details of the error
      # @param status_code [Integer] HTTP status code
      # @param response [HTTP::Response]
      def initialize(message = nil, error_code:, details:, status_code:, response:)
        @error_code = error_code
        @details = details
        @status_code = status_code
        @response = response

        super(message || build_message)
      end

      private

      def build_message
        msg = "Zoho CRM API error -- code: #{error_code.inspect} - HTTP status code: #{status_code}"

        if details.key?("api_name")
          "#{msg} - Field API Name: #{details.fetch("api_name").inspect}"
        else
          msg
        end
      end
    end
  end
end
