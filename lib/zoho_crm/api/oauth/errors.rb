# frozen_string_literal: true

module ZohoCRM
  module API
    module OAuth
      class Error < ZohoCRM::API::Error
        # @return [ZohoCRM::API::OAuth::Token]
        attr_reader :token

        # @param message [String]
        # @param token [ZohoCRM::API::OAuth::Token]
        def initialize(message = nil, token: nil)
          @token = token

          super(message)
        end
      end

      class RequestError < ZohoCRM::API::HTTPRequestError
      end
    end
  end
end
