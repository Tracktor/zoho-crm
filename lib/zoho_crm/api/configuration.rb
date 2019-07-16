# frozen_string_literal: true

module ZohoCRM
  module API
    class Configuration
      # @return [String]
      attr_reader :region

      # The consumer key generated from the connected app
      # @return [String]
      attr_accessor :client_id

      # The consumer secret generated from the connected app.
      # @return [String]
      attr_accessor :client_secret

      # Data that your application wants to access
      # @return [Array<String>]
      attr_reader :scopes

      # Callback URL that you specified during client registration
      # @return [String]
      attr_accessor :redirect_url

      # @return [Integer]
      attr_accessor :timeout

      # @return [Logger]
      attr_accessor :logger

      # @return [Boolean]
      attr_accessor :sandbox

      # @return [Symbol]
      attr_reader :environment

      ACCOUNTS_URL = "https://accounts.zoho.%s"
      CRM_URL = "https://%s.zoho.%s/crm/"
      API_URL = "https://www.zohoapis.%s/crm/v2"
      SANDBOX_API_URL = "https://sandbox.zohoapis.%s/crm/v2"
      REGIONS = %w[com eu in].freeze

      # @param env [Symbol] Configuration environment
      def initialize(env = :default)
        @region = REGIONS.first
        @scopes = []
        @timeout = 5
        @logger = Logger.new(nil)
        @sandbox = false
        @environment = env
      end

      # @param value [String]
      # @raise [ZohoCRM::API::ConfigurationError] if the provided value is not one of com, eu or in
      def region=(value)
        unless REGIONS.include?(value.to_s)
          error_message = "Invalid region: #{value.inspect}. Acceptable values: #{REGIONS.join(", ")}"
          raise ZohoCRM::API::ConfigurationError.new(error_message)
        end

        @region = value.to_s
      end

      # @param value [Array<String>] data that your application wants to access
      # @return [Array<String>]
      def scopes=(value)
        @scopes = Array(value)
      end

      # Main Zoho API URL
      # @return [String]
      def base_url
        url = sandbox ? SANDBOX_API_URL : API_URL
        format(url, region)
      end

      # @return [String]
      def accounts_url
        format(ACCOUNTS_URL, region)
      end

      # @return [String] the URL of the Zoho CRM
      def crm_url
        format(CRM_URL, sandbox ? "crmsandbox" : "crm", region)
      end

      # @return [String] URL of the Zoho Developer Console
      def developer_console_url
        "#{accounts_url}/developerconsole"
      end
    end

    # @param env [Symbol] Configuration environment
    # @yield [config]
    def self.configure(env = :default)
      yield(config(env))
    end

    # @param env [Symbol] Configuration environment
    # @return [ZohoCRM::API::Configuration]
    def self.config(env = :default)
      configs[env.to_s.to_sym]
    end

    # @return [Hash] A Hash containing the registered configurations
    def self.configs
      @configs ||= Hash.new { |hash, key| hash[key] = Configuration.new(key) }
    end
  end
end
