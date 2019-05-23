# frozen_string_literal: true

module ZohoCRM
  module API
    class Error < StandardError
    end

    class ConfigurationError < Error
    end

    class HTTPRequestError < Error
      # @return [HTTP::Response]
      attr_reader :response

      # @param message [String]
      # @param response [HTTP::Response]
      def initialize(message = nil, response:)
        @response = response
        super(message)
      end
    end

    class APIRequestError < HTTPRequestError
      # @param message [String]
      # @param response [HTTP::Response]
      def initialize(message = nil, response:)
        super(message, response: response)
      end

      # @!attribute [r] description
      # @return [String] the error description
      # @see ZohoCRM::API::StatusCodes::STATUS_CODES
      def description
        @description ||= ZohoCRM::API::StatusCodes.description(status_code)
      rescue ZohoCRM::API::StatusCodes::UnknownStatusCodeError
        ZohoCRM::API.config.logger.warn("Unable to retrieve the Zoho error description.")
        @description = response.status.reason
      end

      protected

      def status_code
        @status_code ||= response.status.code
      end
    end

    class UnauthorizedAPIRequestError < APIRequestError
      protected

      def status_code
        :authorization_error
      end
    end
  end
end
