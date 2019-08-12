# frozen_string_literal: true

module ZohoCRM
  module API
    class Client < Connection
      # Get a record
      #
      # @see https://www.zoho.com/crm/help/developer/api/get-specific-record.html
      #
      # @param record_id [String] the ID of the record
      # @param module_name [String] the name of the Zoho module
      #
      # @raise [ZohoCRM::API::APIRequestError] if the response body contains an error
      #
      # @return [Hash] the record attributes
      def show(record_id, module_name:)
        response = get("#{module_name}/#{record_id}")

        data = response.parse.fetch("data") { [] }
        data = data[0] || {}

        if data["status"] == "error"
          raise ZohoCRM::API::APIRequestError.new(
            error_code: data["code"],
            details: data["details"],
            status_code: response.status.code,
            response: response
          )
        end

        data
      end

      # Create a new record
      #
      # @see https://www.zoho.com/crm/help/developer/api/insert-records.html
      #
      # @param attributes [Hash] Record attributes
      # @param module_name [String] the name of the Zoho module
      #
      # @raise [ZohoCRM::API::Error] when trying to create more than one record
      # @raise [ZohoCRM::API::APIRequestError] if the response body contains an error
      #
      # @return [String] the ID of the new record
      def create(attributes, module_name:)
        if attributes.is_a?(Array) && attributes.size > 1
          raise ZohoCRM::API::Error.new("Can't create more than one record at a time")
        end

        response = post(module_name, body: build_body(attributes))
        data = response.parse.fetch("data") { [] }
        data = data[0] || {}

        if data["status"] == "error"
          raise ZohoCRM::API::APIRequestError.new(
            error_code: data["code"],
            details: data["details"],
            status_code: response.status.code,
            response: response
          )
        end

        data.dig("details", "id")
      end

      # Update a record
      #
      # @see https://www.zoho.com/crm/help/developer/api/update-specific-record.html
      #
      # @param record_id [String] the ID of the record
      # @param attributes [Hash] the new record attributes
      # @param module_name [String] the name of the Zoho module
      #
      # @raise [ZohoCRM::API::APIRequestError] if the response body contains an error
      #
      # @return [Boolean]
      def update(record_id, attributes, module_name:)
        response = put("#{module_name}/#{record_id}", body: build_body(attributes))

        data = response.parse.fetch("data") { [] }
        data = data[0] || {}

        if data["status"] == "error"
          raise ZohoCRM::API::APIRequestError.new(
            error_code: data["code"],
            details: data["details"],
            status_code: response.status.code,
            response: response
          )
        end

        data["status"] == "success"
      end

      # Insert or Update a record
      #
      # @see https://www.zoho.com/crm/help/developer/api/upsert-records.html
      #
      # @param attributes [Hash] the record attributes
      # @param module_name [String] the name of the Zoho module
      # @param duplicate_check_fields [Array] list of fields to check against existing records
      #
      # @raise [ZohoCRM::API::Error] when trying to upsert more than one record
      # @raise [ZohoCRM::API::APIRequestError] if the response body contains an error
      #
      # @return [Hash{String => Boolean,String}] a Hash with two keys:
      #   - <b>+new_record+</b> (+Boolean+) — +true+ if the record was created, +false+ if it was updated
      #   - <b>+id+</b> (+String+) — the ID of the record
      def upsert(attributes, module_name:, duplicate_check_fields: [])
        if attributes.is_a?(Array) && attributes.size > 1
          raise ZohoCRM::API::Error.new("Can't upsert more than one record at a time")
        end

        body = build_body(attributes)
        body[:duplicate_check_fields] = Array(duplicate_check_fields)

        response = post("#{module_name}/upsert", body: body)
        data = response.parse.fetch("data") { [] }
        data = data[0] || {}

        if data["status"] == "error"
          raise ZohoCRM::API::APIRequestError.new(
            error_code: data["code"],
            details: data["details"],
            status_code: response.status.code,
            response: response
          )
        end

        {"new_record" => data["action"] == "insert", "id" => data.dig("details", "id")}
      end

      # Delete a record
      #
      # @see https://www.zoho.com/crm/help/developer/api/delete-specific-record.html
      #
      # @param record_id [String] the ID of the record
      # @param module_name [String] the name of the Zoho module
      #
      # @raise [ZohoCRM::API::APIRequestError] if the response body contains an error
      #
      # @return [Boolean]
      def destroy(record_id, module_name:)
        response = delete("#{module_name}/#{record_id}")

        data = response.parse.fetch("data") { [] }
        data = data[0] || {}

        if data["status"] == "error"
          raise ZohoCRM::API::APIRequestError.new(
            error_code: data["code"],
            details: data["details"],
            status_code: response.status.code,
            response: response
          )
        end

        data["status"] == "success"
      end

      private

      def build_body(body)
        {data: [body].flatten(1)}
      end
    end
  end
end
