# frozen_string_literal: true

module ZohoCRM
  module API
    module OAuth
      class Token
        # @return [String]
        attr_reader :access_token

        # @return [String]
        attr_reader :refresh_token

        # @return [Integer]
        attr_reader :expires_in_sec

        # @return [Integer]
        attr_reader :expires_in

        # @return [String]
        attr_reader :token_type

        # @return [String]
        attr_reader :api_domain

        # @overload refresh_time
        #   @return [Time] The UTC time when the access token was last refreshed
        #
        # @overload refresh_time=(value)
        #   @param value [Time, Date, DateTime, Integer, String, NilClass]
        #   @raise [TypeError]
        #   @return [Time] The UTC time when the access token was last refreshed
        attr_reader :refresh_time

        # Parse the JSON string and builds a token with the provided attributes
        #
        # @note The JSON string must be an object so that it will be parsed into a +Hash+
        #
        # @param json_string [String] JSON string to parse
        #
        # @return [ZohoCRM::API::OAuth::Token] a new token
        def self.from_json(json_string)
          attributes = JSON.parse(json_string)

          new(attributes)
        end

        # @param attributes [Hash] Token attributes
        # @option attributes [String] "access_token"
        # @option attributes [String] "refresh_token"
        # @option attributes [Integer] "expires_in_sec"
        # @option attributes [Integer] "expires_in"
        # @option attributes [String] "token_type"
        # @option attributes [String] "api_domain"
        # @option attributes [Time, Date, DateTime, Integer, String] "refresh_time"
        def initialize(attributes = {})
          self.access_token = attributes["access_token"]
          self.refresh_token = attributes["refresh_token"]
          self.expires_in_sec = attributes["expires_in_sec"]
          self.expires_in = attributes["expires_in"]
          self.token_type = attributes["token_type"]
          self.api_domain = attributes["api_domain"]
          self.refresh_time = attributes["refresh_time"]
        end

        # @return [Boolean]
        def expired?
          access_token.to_s.empty? || expires_in_sec.nil? || refresh_time.nil? ||
            Time.now.utc > refresh_time.utc + expires_in_sec
        end

        def access_token=(value)
          @access_token = value.nil? || value.to_s.empty? ? nil : value.to_s
        end

        def refresh_token=(value)
          @refresh_token = value.nil? || value.to_s.empty? ? nil : value.to_s
        end

        def expires_in_sec=(value)
          @expires_in_sec = value.nil? ? nil : value.to_i
          @expires_in = @expires_in_sec.nil? ? nil : @expires_in_sec * 1000
        end

        def expires_in=(value)
          @expires_in = value.nil? ? nil : value.to_i
          @expires_in_sec = @expires_in.nil? ? nil : @expires_in / 1000
        end

        def token_type=(value)
          @token_type = value.nil? || value.to_s.empty? ? nil : value.to_s
        end

        def api_domain=(value)
          @api_domain = value.nil? || value.to_s.empty? ? nil : value.to_s
        end

        def refresh_time=(value)
          @refresh_time =
            case value
            when Time
              value.utc
            when Date, DateTime
              value.to_time.utc
            when Integer
              Time.at(value).utc
            when String
              Time.parse(value).utc
            when NilClass
              nil
            else
              raise TypeError.new("no implicit conversion of #{value.class} into Time")
            end
        end

        def to_h
          {
            "access_token" => access_token,
            "refresh_token" => refresh_token,
            "expires_in_sec" => expires_in_sec,
            "expires_in" => expires_in,
            "token_type" => token_type,
            "api_domain" => api_domain,
          }
        end
        alias to_hash to_h

        # Sets the token attributes from a JSON string.
        #
        # @param json_string [String] JSON string to parse
        #
        # @return [self]
        def from_json(json_string)
          attributes = JSON.parse(json_string)

          self.access_token = attributes["access_token"]
          self.refresh_token = attributes["refresh_token"]
          self.expires_in_sec = attributes["expires_in_sec"]
          self.expires_in = attributes["expires_in"]
          self.token_type = attributes["token_type"]
          self.api_domain = attributes["api_domain"]
          self
        end

        # Dump the token to a JSON string
        #
        # @return [String] a JSON string
        def to_json(*args)
          {
            "access_token" => access_token,
            "refresh_token" => refresh_token,
            "expires_in_sec" => expires_in_sec,
            "expires_in" => expires_in,
            "token_type" => token_type,
            "api_domain" => api_domain,
          }.to_json(*args)
        end
      end
    end
  end
end
