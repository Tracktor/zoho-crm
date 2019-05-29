# frozen_string_literal: true

module ZohoCRM
  module API
    def self.http_client
      HTTP.timeout(config.timeout)
    end
  end
end
