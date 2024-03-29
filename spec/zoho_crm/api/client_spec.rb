# frozen_string_literal: true

RSpec.describe ZohoCRM::API::Client do
  # Stub all HTTP requests
  before { allow_any_instance_of(described_class).to receive(:http).and_return(spy) }

  it "inherits from ZohoCRM::API::Connection" do
    expect(described_class.superclass).to be(ZohoCRM::API::Connection)
  end

  describe "#initialize" do
    context "when a triggers parameter is given" do
      it "sets the default triggers to the value of the parameter" do
        triggers = %w[blueprint]
        client = described_class.new(spy, triggers: triggers)

        expect(client.triggers).to match_array(triggers)
      end
    end

    context "when no triggers parameter is given" do
      it "sets the default triggers" do
        client = described_class.new(spy)

        expect(client.triggers).to match_array([])
      end
    end
  end

  describe "#show" do
    subject(:client) { described_class.new(spy) }

    it "requires a record ID and a module name", aggregate_failures: true do
      expect { client.show }.to raise_error(ArgumentError, "wrong number of arguments (given 0, expected 1; required keyword: module_name)")
      expect { client.show(42) }.to raise_error(ArgumentError, "missing keyword: module_name")
    end

    it "performs a GET request" do
      allow(client).to receive(:get).and_return(spy)

      client.show(42, module_name: "Contacts")

      expect(client).to have_received(:get).with("Contacts/42")
    end

    context "when the request succeeds" do
      it "returns the record attributes" do
        data = {"status" => "success", "id" => "12345678987654321"}

        allow(client).to receive(:get).and_return(spy("Response", parse: {"data" => [data]}))

        expect(client.show({}, module_name: "Contacts")).to eq(data)
      end
    end

    context "when the request fails" do
      it "raises an error", aggregate_failures: true do
        fake_response = spy("Response", {
          status: spy(code: 404),
          parse: {"data" => [{"code" => "NOT_FOUND", "details" => {}, "status" => "error"}]},
        })

        allow(client).to receive(:get).and_return(fake_response)

        expect { client.show("42", module_name: "Contacts") }.to raise_error(ZohoCRM::API::APIRequestError) do |error|
          expect(error.error_code).to eq("NOT_FOUND")
          expect(error.details).to eq({})
          expect(error.status_code).to eq(404)
          expect(error.response).to eq(fake_response)
        end
      end
    end
  end

  describe "#create" do
    it "requires a record ID and a module name", aggregate_failures: true do
      client = described_class.new(spy)

      expect { client.create }.to raise_error(ArgumentError, "wrong number of arguments (given 0, expected 1; required keyword: module_name)")
      expect { client.create(42, {}) }.to raise_error(ArgumentError, "missing keyword: module_name")
    end

    it "performs a POST request" do
      client = described_class.new(spy)

      allow(client).to receive(:post).and_return(spy(parse: {"data" => [{}]}))

      client.create({}, module_name: "Contacts")

      expect(client).to have_received(:post).with("Contacts", body: {data: [{}], trigger: []})
    end

    it "can't create multiple records at the same time", aggregate_failures: true do
      client = described_class.new(spy)

      allow(client).to receive(:post)

      expect { client.create([{name: "John"}, {name: "Jane"}], module_name: "Contacts") }
        .to raise_error(ZohoCRM::API::Error, "Can't create more than one record at a time")

      expect(client).to_not have_received(:post)
    end

    it "accepts a list of workflows to trigger" do
      client = described_class.new(spy, triggers: %w[workflow])

      allow(client).to receive(:post).and_return(spy)

      client.create({}, module_name: "Contacts", trigger: %w[approval blueprint])

      expect(client).to have_received(:post).with("Contacts", body: {data: [{}], trigger: %w[approval blueprint]})
    end

    it "uses the triggers attribute by default" do
      client = described_class.new(spy, triggers: %w[blueprint])

      allow(client).to receive(:post).and_return(spy)

      client.create({}, module_name: "Contacts")

      expect(client).to have_received(:post).with("Contacts", body: {data: [{}], trigger: client.triggers})
    end

    context "when an invalid trigger is passed" do
      it "shows a warning" do
        triggers = %w[bomb]
        warning_message = "warning: invalid triggers found: #{triggers.inspect}\n"
        client = described_class.new(spy)

        allow(Warning).to receive(:warn)
        allow(client).to receive(:post).and_return(spy)

        client.create({}, module_name: "Contacts", trigger: triggers)

        expect(Warning).to have_received(:warn).with(warning_message)
      end
    end

    context "when the request succeeds" do
      subject(:client) { described_class.new(spy) }

      let(:record_id) { "12345678987654321" }

      before do
        fake_response = spy("Response", parse: {"data" => [{"status" => "success", "details" => {"id" => record_id}}]})

        allow(client).to receive(:post).and_return(fake_response)
      end

      it "returns the new record ID" do
        expect(client.create({}, module_name: "Contacts")).to eq(record_id)
      end
    end

    context "when the request fails" do
      subject(:client) { described_class.new(spy) }

      it "raises an error", aggregate_failures: true do
        fake_response = spy("Response", {
          status: spy(code: 202),
          parse: {"data" => [{"code" => "ERROR", "details" => {}, "status" => "error"}]},
        })

        allow(client).to receive(:post).and_return(fake_response)

        expect { client.create({}, module_name: "Contacts") }.to raise_error(ZohoCRM::API::APIRequestError) do |error|
          expect(error.error_code).to eq("ERROR")
          expect(error.details).to eq({})
          expect(error.status_code).to eq(202)
          expect(error.response).to eq(fake_response)
        end
      end
    end

    context "when the resquest fails with an \"INVALID_DATA\" error code and no details" do
      subject(:client) { described_class.new(spy) }

      it "raises an error", aggregate_failures: true do
        fake_response = spy("Response", {
          status: spy(code: 202),
          parse: {"data" => [{"code" => "INVALID_DATA", "details" => {}, "message" =>  "an error message", "status" => "error"}]},
        })

        allow(client).to receive(:post).and_return(fake_response)

        expect { client.create({}, module_name: "Contacts") }.to raise_error(ZohoCRM::API::InvalidDataError) do |error|
          expect(error.message).to eq("an error message")
          expect(error.field_name).to eq(nil)
          expect(error.error_code).to eq("INVALID_DATA")
          expect(error.details).to eq({})
          expect(error.status_code).to eq(202)
          expect(error.response).to eq(fake_response)
        end
      end
    end

    context "when the request fails with an \"INVALID_DATA\" error_code and details" do
      subject(:client) { described_class.new(spy) }

      it "raises an error", aggregate_failures: true do
        api_name = "First_Name"
        fake_response = spy("Response", {
          status: spy(code: 202),
          parse: {"data" => [{"code" => "INVALID_DATA", "details" => {"api_name" => api_name}, "status" => "error"}]},
        })

        allow(client).to receive(:post).and_return(fake_response)

        expect { client.create({}, module_name: "Contacts") }.to raise_error(ZohoCRM::API::InvalidDataError) do |error|
          expect(error.field_name).to eq(api_name)
          expect(error.error_code).to eq("INVALID_DATA")
          expect(error.details).to eq({"api_name" => "First_Name"})
          expect(error.status_code).to eq(202)
          expect(error.response).to eq(fake_response)
        end
      end
    end

    context "when the request fails with an \"DUPLICATE_DATA\" error_code" do
      subject(:client) { described_class.new(spy) }

      it "raises an error", aggregate_failures: true do
        fake_response = spy("Response", {
          status: spy(code: 202),
          parse: {"data" => [{"code" => "DUPLICATE_DATA", "details" => {"api_name" => "First_Name"}, "status" => "error"}]},
        })

        allow(client).to receive(:post).and_return(fake_response)

        expect { client.create({}, module_name: "Contacts") }.to raise_error(ZohoCRM::API::DuplicateDataError) do |error|
          expect(error.error_code).to eq("DUPLICATE_DATA")
          expect(error.details).to eq({"api_name" => "First_Name"})
          expect(error.status_code).to eq(202)
          expect(error.response).to eq(fake_response)
        end
      end
    end
  end

  describe "#update" do
    it "requires a record ID, a body and a module name", aggregate_failures: true do
      client = described_class.new(spy)

      expect { client.update }.to raise_error(ArgumentError, "wrong number of arguments (given 0, expected 2; required keyword: module_name)")
      expect { client.update(42) }.to raise_error(ArgumentError, "wrong number of arguments (given 1, expected 2; required keyword: module_name)")
      expect { client.update(42, {}) }.to raise_error(ArgumentError, "missing keyword: module_name")
    end

    it "performs a PUT request" do
      client = described_class.new(spy)

      allow(client).to receive(:put).and_return(spy)

      client.update(42, {}, module_name: "Contacts")

      expect(client).to have_received(:put).with("Contacts/42", body: {data: [{}], trigger: []})
    end

    it "accepts a list of workflows to trigger" do
      client = described_class.new(spy, triggers: %w[blueprint])

      allow(client).to receive(:put).and_return(spy)

      client.update(42, {}, module_name: "Contacts", trigger: %w[approval])

      expect(client).to have_received(:put).with("Contacts/42", body: {data: [{}], trigger: %w[approval]})
    end

    it "uses the triggers attribute by default" do
      client = described_class.new(spy, triggers: %w[blueprint])

      allow(client).to receive(:put).and_return(spy)

      client.update(42, {}, module_name: "Contacts")

      expect(client).to have_received(:put).with("Contacts/42", body: {data: [{}], trigger: client.triggers})
    end

    context "when an invalid trigger is passed" do
      it "shows a warning" do
        triggers = %w[bomb]
        warning_message = "warning: invalid triggers found: #{triggers.inspect}\n"
        client = described_class.new(spy)

        allow(Warning).to receive(:warn)
        allow(client).to receive(:put).and_return(spy)

        client.update(42, {}, module_name: "Contacts", trigger: triggers)

        expect(Warning).to have_received(:warn).with(warning_message)
      end
    end

    context "when the request succeeds" do
      subject(:client) { described_class.new(spy) }

      it "returns true" do
        fake_response = spy("Response", parse: {"data" => [{"status" => "success"}]})

        allow(client).to receive(:put).and_return(fake_response)

        expect(client.update("42", {}, module_name: "Contacts")).to be(true)
      end
    end

    context "when the request fails" do
      subject(:client) { described_class.new(spy) }

      it "raises an error", aggregate_failures: true do
        fake_response = spy("Response", {
          status: spy(code: 202),
          parse: {"data" => [{"code" => "ERROR", "details" => {}, "status" => "error"}]},
        })

        allow(client).to receive(:put).and_return(fake_response)

        expect { client.update("42", {}, module_name: "Contacts") }.to raise_error(ZohoCRM::API::APIRequestError) do |error|
          expect(error.error_code).to eq("ERROR")
          expect(error.details).to eq({})
          expect(error.status_code).to eq(202)
          expect(error.response).to eq(fake_response)
        end
      end
    end

    context "when the resquest fails with an \"INVALID_DATA\" error code and no details" do
      subject(:client) { described_class.new(spy) }

      it "raises an error", aggregate_failures: true do
        fake_response = spy("Response", {
          status: spy(code: 202),
          parse: {"data" => [{"code" => "INVALID_DATA", "details" => {}, "message" =>  "an error message", "status" => "error"}]},
        })

        allow(client).to receive(:put).and_return(fake_response)

        expect { client.update("42", {}, module_name: "Contacts") }.to raise_error(ZohoCRM::API::InvalidDataError) do |error|
          expect(error.message).to eq("an error message")
          expect(error.field_name).to eq(nil)
          expect(error.error_code).to eq("INVALID_DATA")
          expect(error.details).to eq({})
          expect(error.status_code).to eq(202)
          expect(error.response).to eq(fake_response)
        end
      end
    end

    context "when the request fails with an \"INVALID_DATA\" error_code and details" do
      subject(:client) { described_class.new(spy) }

      it "raises an error", aggregate_failures: true do
        api_name = "First_Name"
        fake_response = spy("Response", {
          status: spy(code: 202),
          parse: {"data" => [{"code" => "INVALID_DATA", "details" => {"api_name" => api_name}, "status" => "error"}]},
        })

        allow(client).to receive(:put).and_return(fake_response)

        expect { client.update("42", {}, module_name: "Contacts") }.to raise_error(ZohoCRM::API::InvalidDataError) do |error|
          expect(error.field_name).to eq(api_name)
          expect(error.error_code).to eq("INVALID_DATA")
          expect(error.details).to eq({"api_name" => "First_Name"})
          expect(error.status_code).to eq(202)
          expect(error.response).to eq(fake_response)
        end
      end
    end

    context "when the request fails with an \"DUPLICATE_DATA\" error_code" do
      subject(:client) { described_class.new(spy) }

      it "raises an error", aggregate_failures: true do
        fake_response = spy("Response", {
          status: spy(code: 202),
          parse: {"data" => [{"code" => "DUPLICATE_DATA", "details" => {"api_name" => "First_Name"}, "status" => "error"}]},
        })

        allow(client).to receive(:put).and_return(fake_response)

        expect { client.update("42", {}, module_name: "Contacts") }.to raise_error(ZohoCRM::API::DuplicateDataError) do |error|
          expect(error.error_code).to eq("DUPLICATE_DATA")
          expect(error.details).to eq({"api_name" => "First_Name"})
          expect(error.status_code).to eq(202)
          expect(error.response).to eq(fake_response)
        end
      end
    end
  end

  describe "#upsert" do
    it "requires a record ID and a module name", aggregate_failures: true do
      client = described_class.new(spy)

      expect { client.upsert }.to raise_error(ArgumentError, "wrong number of arguments (given 0, expected 1; required keyword: module_name)")
      expect { client.upsert(42) }.to raise_error(ArgumentError, "missing keyword: module_name")
    end

    it "performs a POST request" do
      client = described_class.new(spy)

      allow(client).to receive(:post).and_return(spy)

      client.upsert([{}], module_name: "Contacts")

      expect(client).to have_received(:post).with("Contacts/upsert", body: {data: [{}], duplicate_check_fields: [], trigger: []})
    end

    it "can't upsert multiple records at the same time" do
      client = described_class.new(spy)

      allow(client).to receive(:post)

      expect { client.upsert([{name: "John"}, {name: "Jane"}], module_name: "Contacts") }
        .to raise_error(ZohoCRM::API::Error, "Can't upsert more than one record at a time")

      expect(client).to_not have_received(:post)
    end

    it "accepts a list of fields to check for existing records" do
      client = described_class.new(spy)

      allow(client).to receive(:post).and_return(spy)

      client.upsert([{}], module_name: "Contacts", duplicate_check_fields: %w[email last_name])

      expect(client).to have_received(:post).with("Contacts/upsert", body: {
        data: [{}],
        duplicate_check_fields: %w[email last_name],
        trigger: [],
      })
    end

    it "accepts a list of workflows to trigger" do
      client = described_class.new(spy, triggers: %w[workflow])

      allow(client).to receive(:post).and_return(spy)

      client.upsert([{}], module_name: "Contacts", trigger: %w[blueprint])

      expect(client).to have_received(:post).with("Contacts/upsert", body: {
        data: [{}],
        duplicate_check_fields: [],
        trigger: %w[blueprint],
      })
    end

    it "uses the triggers attribute by default" do
      client = described_class.new(spy, triggers: %w[workflow])

      allow(client).to receive(:post).and_return(spy)

      client.upsert([{}], module_name: "Contacts")

      expect(client).to have_received(:post).with("Contacts/upsert", body: {
        data: [{}],
        duplicate_check_fields: [],
        trigger: client.triggers,
      })
    end

    context "when an invalid trigger is passed" do
      it "shows a warning" do
        triggers = %w[bomb]
        warning_message = "warning: invalid triggers found: #{triggers.inspect}\n"
        client = described_class.new(spy)

        allow(Warning).to receive(:warn)
        allow(client).to receive(:post).and_return(spy)

        client.upsert([{}], module_name: "Contacts", trigger: triggers)

        expect(Warning).to have_received(:warn).with(warning_message)
      end
    end

    context "when the request succeeds" do
      subject(:client) { described_class.new(spy) }

      context "when a new record was created" do
        let(:record_id) { "12345678987654321" }

        before do
          fake_response = spy("Response", parse: {"data" => [{
            "status" => "success",
            "action" => "insert",
            "details" => {"id" => record_id},
          }]})

          allow(client).to receive(:post).and_return(fake_response)
        end

        it "returns a Hash with the :new_record key set to true" do
          expect(client.upsert({}, module_name: "Contacts"))
            .to eq({"new_record" => true, "id" => record_id})
        end
      end

      context "when an existing record was updated" do
        let(:record_id) { "12345678987654321" }

        before do
          fake_response = spy("Response", parse: {"data" => [{
            "status" => "success",
            "action" => "update",
            "details" => {"id" => record_id},
          }]})

          allow(client).to receive(:post).and_return(fake_response)
        end

        it "returns a Hash with the :new_record key set to false" do
          expect(client.upsert({}, module_name: "Contacts"))
            .to eq({"new_record" => false, "id" => record_id})
        end
      end
    end

    context "when the request fails" do
      subject(:client) { described_class.new(spy) }

      it "raises an error", aggregate_failures: true do
        fake_response = spy("Response", {
          status: spy(code: 202),
          parse: {"data" => [{"code" => "ERROR", "details" => {}, "status" => "error"}]},
        })

        allow(client).to receive(:post).and_return(fake_response)

        expect { client.upsert({}, module_name: "Contacts") }.to raise_error(ZohoCRM::API::APIRequestError) do |error|
          expect(error.error_code).to eq("ERROR")
          expect(error.details).to eq({})
          expect(error.status_code).to eq(202)
          expect(error.response).to eq(fake_response)
        end
      end
    end

    context "when the resquest fails with an \"INVALID_DATA\" error code and no details" do
      subject(:client) { described_class.new(spy) }

      it "raises an error", aggregate_failures: true do
        fake_response = spy("Response", {
          status: spy(code: 202),
          parse: {"data" => [{"code" => "INVALID_DATA", "details" => {}, "message" =>  "an error message", "status" => "error"}]},
        })

        allow(client).to receive(:post).and_return(fake_response)

        expect { client.upsert({}, module_name: "Contacts") }.to raise_error(ZohoCRM::API::InvalidDataError) do |error|
          expect(error.message).to eq("an error message")
          expect(error.field_name).to eq(nil)
          expect(error.error_code).to eq("INVALID_DATA")
          expect(error.details).to eq({})
          expect(error.status_code).to eq(202)
          expect(error.response).to eq(fake_response)
        end
      end
    end

    context "when the request fails with an \"INVALID_DATA\" error_code and details" do
      subject(:client) { described_class.new(spy) }

      it "raises an error", aggregate_failures: true do
        api_name =  "First_Name"
        fake_response = spy("Response", {
          status: spy(code: 202),
          parse: {"data" => [{"code" => "INVALID_DATA", "details" => {"api_name" => api_name}, "status" => "error"}]},
        })

        allow(client).to receive(:post).and_return(fake_response)

        expect { client.upsert({}, module_name: "Contacts") }.to raise_error(ZohoCRM::API::InvalidDataError) do |error|
          expect(error.error_code).to eq("INVALID_DATA")
          expect(error.field_name).to eq(api_name)
          expect(error.details).to eq({"api_name" => "First_Name"})
          expect(error.status_code).to eq(202)
          expect(error.response).to eq(fake_response)
        end
      end
    end

    context "when the request fails with an \"DUPLICATE_DATA\" error_code" do
      subject(:client) { described_class.new(spy) }

      it "raises an error", aggregate_failures: true do
        fake_response = spy("Response", {
          status: spy(code: 202),
          parse: {"data" => [{"code" => "DUPLICATE_DATA", "details" => {"api_name" => "First_Name"}, "status" => "error"}]},
        })

        allow(client).to receive(:post).and_return(fake_response)

        expect { client.upsert({}, module_name: "Contacts") }.to raise_error(ZohoCRM::API::DuplicateDataError) do |error|
          expect(error.error_code).to eq("DUPLICATE_DATA")
          expect(error.details).to eq({"api_name" => "First_Name"})
          expect(error.status_code).to eq(202)
          expect(error.response).to eq(fake_response)
        end
      end
    end
  end

  describe "#destroy" do
    subject(:client) { described_class.new(spy) }

    it "requires a record ID and a module name", aggregate_failures: true do
      expect { client.destroy }.to raise_error(ArgumentError, "wrong number of arguments (given 0, expected 1; required keyword: module_name)")
      expect { client.destroy(42) }.to raise_error(ArgumentError, "missing keyword: module_name")
    end

    it "performs a DELETE request" do
      allow(client).to receive(:delete).and_return(spy)

      client.destroy(42, module_name: "Contacts")

      expect(client).to have_received(:delete).with("Contacts/42")
    end

    context "when the request succeeds" do
      it "returns true" do
        allow(client).to receive(:delete).and_return(spy("Response", parse: {"data" => [{"status" => "success"}]}))

        expect(client.destroy(42, module_name: "Contacts")).to be(true)
      end
    end

    context "when the request fails" do
      it "raises an error", aggregate_failures: true do
        fake_response = spy("Response", {
          status: spy(code: 400),
          parse: {"data" => [{"code" => "ERROR", "details" => {}, "status" => "error"}]},
        })

        allow(client).to receive(:delete).and_return(fake_response)

        expect { client.destroy("42", module_name: "Contacts") }.to raise_error(ZohoCRM::API::APIRequestError) do |error|
          expect(error.error_code).to eq("ERROR")
          expect(error.details).to eq({})
          expect(error.status_code).to eq(400)
          expect(error.response).to eq(fake_response)
        end
      end
    end

    context "when the resquest fails with an \"INVALID_DATA\" error code and no details" do
      subject(:client) { described_class.new(spy) }

      it "raises an error", aggregate_failures: true do
        fake_response = spy("Response", {
          status: spy(code: 202),
          parse: {"data" => [{"code" => "INVALID_DATA", "details" => {}, "message" =>  "an error message", "status" => "error"}]},
        })

        allow(client).to receive(:delete).and_return(fake_response)

        expect { client.destroy("42", module_name: "Contacts") }.to raise_error(ZohoCRM::API::InvalidDataError) do |error|
          expect(error.message).to eq("an error message")
          expect(error.field_name).to eq(nil)
          expect(error.error_code).to eq("INVALID_DATA")
          expect(error.details).to eq({})
          expect(error.status_code).to eq(202)
          expect(error.response).to eq(fake_response)
        end
      end
    end
    context "when the request fails with an \"INVALID_DATA\" error_code" do
      it "raises an error", aggregate_failures: true do
        api_name = "First_Name"
        fake_response = spy("Response", {
          status: spy(code: 202),
          parse: {"data" => [{"code" => "INVALID_DATA", "details" => {"api_name" => api_name}, "status" => "error"}]},
        })

        allow(client).to receive(:delete).and_return(fake_response)

        expect { client.destroy("42", module_name: "Contacts") }.to raise_error(ZohoCRM::API::InvalidDataError) do |error|
          expect(error.error_code).to eq("INVALID_DATA")
          expect(error.field_name).to eq(api_name)
          expect(error.details).to eq({"api_name" => "First_Name"})
          expect(error.status_code).to eq(202)
          expect(error.response).to eq(fake_response)
        end
      end
    end

    context "when the request fails with an \"DUPLICATE_DATA\" error_code" do
      it "raises an error", aggregate_failures: true do
        fake_response = spy("Response", {
          status: spy(code: 202),
          parse: {"data" => [{"code" => "DUPLICATE_DATA", "details" => {"api_name" => "First_Name"}, "status" => "error"}]},
        })

        allow(client).to receive(:delete).and_return(fake_response)

        expect { client.destroy("42", module_name: "Contacts") }.to raise_error(ZohoCRM::API::DuplicateDataError) do |error|
          expect(error.error_code).to eq("DUPLICATE_DATA")
          expect(error.details).to eq({"api_name" => "First_Name"})
          expect(error.status_code).to eq(202)
          expect(error.response).to eq(fake_response)
        end
      end
    end
  end
end
