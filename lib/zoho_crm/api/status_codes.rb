module ZohoCRM
  module API
    class StatusCodes
      class UnknownStatusCodeError < ZohoCRM::API::Error
        attr_reader :status_code

        def initialize(code:)
          @status_code = code
          message = "Unknown HTTP status code: #{@status_code.inspect}"

          super(message)
        end
      end

      STATUS_CODES = {
        ok: {
          code: 200,
          meaning: "OK",
          description: "The API request is successful.",
        }.freeze,

        created: {
          code: 201,
          meaning: "CREATED",
          description: "Request fulfilled for single record insertion.",
        }.freeze,

        accepted: {
          code: 202,
          meaning: "ACCEPTED",
          description: "Request fulfilled for multiple records insertion.",
        }.freeze,

        no_content: {
          code: 204,
          meaning: "NO_CONTENT",
          description: "There is no content available for the request.",
        }.freeze,

        not_modified: {
          code: 304,
          meaning: "NOT_MODIFIED",
          description: "The requested page has not been modified. In case \"If-Modified-Since\" header is used for GET APIs",
        }.freeze,

        bad_request: {
          code: 400,
          meaning: "BAD_REQUEST",
          description: "The request or the authentication considered is invalid.",
        }.freeze,

        authorization_error: {
          code: 401,
          meaning: "AUTHORIZATION_ERROR",
          description: "Invalid API key provided.",
        }.freeze,

        forbidden: {
          code: 403,
          meaning: "FORBIDDEN",
          description: "No permission to do the operation.",
        }.freeze,

        not_found: {
          code: 404,
          meaning: "NOT_FOUND",
          description: "Invalid request.",
        }.freeze,

        method_not_allowed: {
          code: 405,
          meaning: "METHOD_NOT_ALLOWED",
          description: "The specified method is not allowed.",
        }.freeze,

        request_entity_too_large: {
          code: 413,
          meaning: "REQUEST_ENTITY_TOO_LARGE",
          description: "The server did not accept the request while uploading a file, since the limited file size has exceeded.",
        }.freeze,

        unsupported_media_type: {
          code: 415,
          meaning: "UNSUPPORTED_MEDIA_TYPE",
          description: "The server did not accept the request while uploading a file, since the media/ file type is not supported.",
        }.freeze,

        too_many_requests: {
          code: 429,
          meaning: "TOO_MANY_REQUESTS",
          description: "Number of API requests for the 24 hour period is exceeded or the concurrency limit of the user for the app is exceeded.",
        }.freeze,

        internal_server_error: {
          code: 500,
          meaning: "INTERNAL_SERVER_ERROR",
          description: "Generic error that is encountered due to an unexpected server error.",
        }.freeze,
      }.freeze

      class << self
        def code(key_or_code)
          status_code = self[key_or_code]

          if status_code
            status_code[:code]
          else
            raise UnknownStatusCodeError.new(code: key_or_code)
          end
        end

        def meaning(key_or_code)
          status_code = self[key_or_code]

          if status_code
            status_code[:meaning]
          else
            raise UnknownStatusCodeError.new(code: key_or_code)
          end
        end

        def description(key_or_code)
          status_code = self[key_or_code]

          if status_code
            status_code[:description]
          else
            raise UnknownStatusCodeError.new(code: key_or_code)
          end
        end

        def [](key_or_code)
          STATUS_CODES.fetch(key_or_code.to_s.downcase.to_sym) {
            STATUS_CODES.values.find { |value| value[:code] == key_or_code }
          }
        end

        def inspect(verbose = false)
          if verbose
            STATUS_CODES
          else
            Hash[STATUS_CODES.map { |key, value| [key, value[:code]] }]
          end
        end

        def method_missing(method_name, *args)
          key = method_name.to_s.to_sym

          if STATUS_CODES.key?(key)
            STATUS_CODES[key][:code]
          else
            super
          end
        end

        def respond_to_missing?(method_name, include_all)
          STATUS_CODES.key?(method_name.to_s.to_sym) || super
        end

        def const_missing(const_name)
          key = const_name.to_s.downcase.to_sym

          if STATUS_CODES.key?(key)
            STATUS_CODES[key][:code]
          else
            super
          end
        end
      end
    end
  end
end
