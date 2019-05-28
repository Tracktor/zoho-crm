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
      def show(record_id, module_name:)
        get("#{module_name}/#{record_id}")
      end

      # Add a new record to a module.
      #
      # @see https://www.zoho.com/crm/help/developer/api/insert-records.html
      #
      # @param attributes [Array, Hash] Record attributes
      # @param module_name [String] the name of the Zoho module
      def create(attributes, module_name:)
        post(module_name, body: build_body(attributes))
      end

      # Update a record
      #
      # @see https://www.zoho.com/crm/help/developer/api/update-specific-record.html
      #
      # @param record_id [String] the ID of the record
      # @param attributes [Hash] the new record attributes
      # @param module_name [String] the name of the Zoho module
      def update(record_id, attributes, module_name:)
        put("#{module_name}/#{record_id}", body: build_body(attributes))
      end

      # Insert or Update a record
      #
      # @see https://www.zoho.com/crm/help/developer/api/upsert-records.html
      #
      # @param attributes [Hash] the record attributes
      # @param module_name [String] the name of the Zoho module
      # @param duplicate_check_fields [Array] list of fields to check against existing records
      def upsert(attributes, module_name:, duplicate_check_fields: [])
        body = build_body(attributes)
        body[:duplicate_check_fields] = Array(duplicate_check_fields).join(",")

        post("#{module_name}/upsert", body: body)
      end

      # Delete a record
      #
      # @see https://www.zoho.com/crm/help/developer/api/delete-specific-record.html
      #
      # @param record_id [String] the ID of the record
      # @param module_name [String] the name of the Zoho module
      def destroy(record_id, module_name:)
        delete("#{module_name}/#{record_id}")
      end

      private

      def build_body(body)
        {data: [body].flatten}
      end
    end
  end
end
