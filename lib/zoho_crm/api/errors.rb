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

      # @param (see #initialize)
      #
      # @raise [KeyError] if +error_code+ is +"INVALID_DATA"+ and the +details+ Hash doesn't have the +"api_name"+ key.
      # @raise [KeyError] if +error_code+ is +"DUPLICATE_DATA"+ and the +details+ Hash doesn't have the +"api_name"+ key.
      #
      # @return [ZohoCRM::API::InvalidDataError] if error_code is +"INVALID_DATA"+
      # @return [ZohoCRM::API::DuplicateDataError] if error_code is +"DUPLICATE_DATA"+
      # @return [ZohoCRM::API::APIRequestError]
      def self.build(message = nil, error_code:, details:, status_code:, response:)
        error_class =
          case error_code.to_s
          when "INVALID_DATA"
            ZohoCRM::API::InvalidDataError
          when "DUPLICATE_DATA"
            ZohoCRM::API::DuplicateDataError
          else
            self
          end

        error_class.new(
          message,
          error_code: error_code,
          details: details,
          status_code: status_code,
          response: response,
        )
      end

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

      protected

      def build_message
        msg = "Zoho CRM API error -- code: #{error_code.inspect} - HTTP status code: #{status_code}"

        if details.key?("api_name")
          "#{msg} - Field API Name: #{details.fetch("api_name").inspect}"
        else
          msg
        end
      end
    end

    class InvalidDataError < APIRequestError
      # @return [String] The api_name of the field with invalid data
      attr_reader :field_name

      # @param (see ZohoCRM::API::APIRequestError#initialize)
      #
      # @raise [ZohoCRM::API::Error] if +error_code+ is not +"INVALID_DATA"+
      # @raise [KeyError] if the +details+ Hash doesn't have the +"api_name"+ key.
      def initialize(message = nil, error_code:, details:, status_code:, response:)
        unless error_code == "INVALID_DATA"
          raise Error.new(%(expected error_code to be "INVALID_DATA" but got #{error_code.inspect}))
        end

        @field_name = details.fetch("api_name", nil)

        super
      end

      protected

      def build_message
        msg = "Zoho CRM API error -- code: #{error_code.inspect} - HTTP status code: #{status_code}"

        if details.key?("api_name")
          "#{msg} - Invalid data for field: #{field_name.inspect}"
        else
          msg
        end
      end
    end

    class DuplicateDataError < APIRequestError
      # @return [String] The api_name of the field with invalid data
      attr_reader :field_name

      # @param (see ZohoCRM::API::APIRequestError#initialize)
      #
      # @raise [ZohoCRM::API::Error] if +error_code+ is not +"DUPLICATE_DATA"+
      # @raise [KeyError] if the +details+ Hash doesn't have the +"api_name"+ key.
      def initialize(message = nil, error_code:, details:, status_code:, response:)
        unless error_code == "DUPLICATE_DATA"
          raise Error.new(%(expected error_code to be "DUPLICATE_DATA" but got #{error_code.inspect}))
        end

        @field_name = details.fetch("api_name")

        super
      end

      protected

      def build_message
        "Duplicate data for field: #{field_name.inspect}"
      end
    end
  end
end
