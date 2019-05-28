# frozen_string_literal: true

module ZohoCRM
  module API
    class Client < Connection
      # Zoho CRM API Docs: {https://www.zoho.com/crm/help/developer/api/get-specific-record.html Get a specific record}
      def show(record_id, module_name:)
        get("#{module_name}/#{record_id}")
      end

      # Zoho CRM API Docs: {https://www.zoho.com/crm/help/developer/api/insert-records.html Insert records}
      def create(records, module_name:)
        post(module_name, body: build_body(records))
      end

      # Zoho CRM API Docs: {https://www.zoho.com/crm/help/developer/api/update-specific-record.html Update a specific record}
      def update(record_id, body, module_name:)
        put("#{module_name}/#{record_id}", body: build_body(body))
      end

      # Zoho CRM API Docs: {https://www.zoho.com/crm/help/developer/api/upsert-records.html Insert or Update records}
      def upsert(records, module_name:, duplicate_check_fields: [])
        body = build_body(records)
        body[:duplicate_check_fields] = Array(duplicate_check_fields).join(",")

        post("#{module_name}/upsert", body: body)
      end

      # Zoho CRM API Docs: {https://www.zoho.com/crm/help/developer/api/delete-specific-record.html Delete a specific record}
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
