# frozen_string_literal: true

RSpec.describe ZohoCRM::API::Client do
  # Stub all HTTP requests
  before { allow_any_instance_of(described_class).to receive(:http).and_return(spy) }

  it "inherits from ZohoCRM::API::Connection" do
    expect(described_class.superclass).to be(ZohoCRM::API::Connection)
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
          status: spy(code: 202),
          parse: {"data" => [{"code" => "INVALID_DATA", "details" => {"api_name" => "First_Name"}, "status" => "error"}]},
        })

        allow(client).to receive(:get).and_return(fake_response)

        expect { client.show("42", module_name: "Contacts") }.to raise_error(ZohoCRM::API::APIRequestError) do |error|
          expect(error.error_code).to eq("INVALID_DATA")
          expect(error.details).to eq({"api_name" => "First_Name"})
          expect(error.status_code).to eq(202)
          expect(error.response).to eq(fake_response)
        end
      end
    end
  end

  describe "#create" do
    subject(:client) { described_class.new(spy) }

    it "requires a record ID and a module name", aggregate_failures: true do
      expect { client.create }.to raise_error(ArgumentError, "wrong number of arguments (given 0, expected 1; required keyword: module_name)")
      expect { client.create(42, {}) }.to raise_error(ArgumentError, "missing keyword: module_name")
    end

    it "performs a POST request" do
      allow(client).to receive(:post).and_return(spy(parse: {"data" => [{}]}))

      client.create({}, module_name: "Contacts")

      expect(client).to have_received(:post).with("Contacts", body: {data: [{}], trigger: []})
    end

    it "can't create multiple records at the same time", aggregate_failures: true do
      allow(client).to receive(:post)

      expect { client.create([{name: "John"}, {name: "Jane"}], module_name: "Contacts") }
        .to raise_error(ZohoCRM::API::Error, "Can't create more than one record at a time")

      expect(client).to_not have_received(:post)
    end

    it "accepts a list of workflows to trigger" do
      allow(client).to receive(:post).and_return(spy)

      client.create({}, module_name: "Contacts", trigger: %w[approval blueprint])

      expect(client).to have_received(:post).with("Contacts", body: {data: [{}], trigger: %w[approval blueprint]})
    end

    it "doesn't trigger any workflow by default" do
      allow(client).to receive(:post).and_return(spy)

      client.create({}, module_name: "Contacts")

      expect(client).to have_received(:post).with("Contacts", body: {data: [{}], trigger: []})
    end

    context "when the request succeeds" do
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
      it "raises an error", aggregate_failures: true do
        fake_response = spy("Response", {
          status: spy(code: 202),
          parse: {"data" => [{"code" => "INVALID_DATA", "details" => {"api_name" => "First_Name"}, "status" => "error"}]},
        })

        allow(client).to receive(:post).and_return(fake_response)

        expect { client.create({}, module_name: "Contacts") }.to raise_error(ZohoCRM::API::APIRequestError) do |error|
          expect(error.error_code).to eq("INVALID_DATA")
          expect(error.details).to eq({"api_name" => "First_Name"})
          expect(error.status_code).to eq(202)
          expect(error.response).to eq(fake_response)
        end
      end
    end
  end

  describe "#update" do
    subject(:client) { described_class.new(spy) }

    it "requires a record ID, a body and a module name", aggregate_failures: true do
      expect { client.update }.to raise_error(ArgumentError, "wrong number of arguments (given 0, expected 2; required keyword: module_name)")
      expect { client.update(42) }.to raise_error(ArgumentError, "wrong number of arguments (given 1, expected 2; required keyword: module_name)")
      expect { client.update(42, {}) }.to raise_error(ArgumentError, "missing keyword: module_name")
    end

    it "performs a PUT request" do
      allow(client).to receive(:put).and_return(spy)

      client.update(42, {}, module_name: "Contacts")

      expect(client).to have_received(:put).with("Contacts/42", body: {data: [{}], trigger: []})
    end

    it "accepts a list of workflows to trigger" do
      allow(client).to receive(:put).and_return(spy)

      client.update(42, {}, module_name: "Contacts", trigger: %w[blueprint])

      expect(client).to have_received(:put).with("Contacts/42", body: {data: [{}], trigger: %w[blueprint]})
    end

    it "doesn't trigger any workflow by default" do
      allow(client).to receive(:put).and_return(spy)

      client.update(42, {}, module_name: "Contacts")

      expect(client).to have_received(:put).with("Contacts/42", body: {data: [{}], trigger: []})
    end

    context "when the request succeeds" do
      it "returns true" do
        fake_response = spy("Response", parse: {"data" => [{"status" => "success"}]})

        allow(client).to receive(:put).and_return(fake_response)

        expect(client.update("42", {}, module_name: "Contacts")).to be(true)
      end
    end

    context "when the request fails" do
      it "raises an error", aggregate_failures: true do
        fake_response = spy("Response", {
          status: spy(code: 202),
          parse: {"data" => [{"code" => "INVALID_DATA", "details" => {"api_name" => "First_Name"}, "status" => "error"}]},
        })

        allow(client).to receive(:put).and_return(fake_response)

        expect { client.update("42", {}, module_name: "Contacts") }.to raise_error(ZohoCRM::API::APIRequestError) do |error|
          expect(error.error_code).to eq("INVALID_DATA")
          expect(error.details).to eq({"api_name" => "First_Name"})
          expect(error.status_code).to eq(202)
          expect(error.response).to eq(fake_response)
        end
      end
    end
  end

  describe "#upsert" do
    subject(:client) { described_class.new(spy) }

    it "requires a record ID and a module name", aggregate_failures: true do
      expect { client.upsert }.to raise_error(ArgumentError, "wrong number of arguments (given 0, expected 1; required keyword: module_name)")
      expect { client.upsert(42) }.to raise_error(ArgumentError, "missing keyword: module_name")
    end

    it "performs a POST request" do
      allow(client).to receive(:post).and_return(spy)

      client.upsert([{}], module_name: "Contacts")

      expect(client).to have_received(:post).with("Contacts/upsert", body: {data: [{}], duplicate_check_fields: [], trigger: []})
    end

    it "can't upsert multiple records at the same time" do
      allow(client).to receive(:post)

      expect { client.upsert([{name: "John"}, {name: "Jane"}], module_name: "Contacts") }
        .to raise_error(ZohoCRM::API::Error, "Can't upsert more than one record at a time")

      expect(client).to_not have_received(:post)
    end

    it "accepts a list of fields to check for existing records" do
      allow(client).to receive(:post).and_return(spy)

      client.upsert([{}], module_name: "Contacts", duplicate_check_fields: %w[email last_name])

      expect(client).to have_received(:post).with("Contacts/upsert", body: {
        data: [{}],
        duplicate_check_fields: %w[email last_name],
        trigger: [],
      })
    end

    it "accepts a list of workflows to trigger" do
      allow(client).to receive(:post).and_return(spy)

      client.upsert([{}], module_name: "Contacts", trigger: %w[blueprint])

      expect(client).to have_received(:post).with("Contacts/upsert", body: {
        data: [{}],
        duplicate_check_fields: [],
        trigger: %w[blueprint],
      })
    end

    it "doesn't trigger any workflow by default" do
      allow(client).to receive(:post).and_return(spy)

      client.upsert([{}], module_name: "Contacts", trigger: [])

      expect(client).to have_received(:post).with("Contacts/upsert", body: {
        data: [{}],
        duplicate_check_fields: [],
        trigger: [],
      })
    end

    context "when the request succeeds" do
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
      it "raises an error", aggregate_failures: true do
        fake_response = spy("Response", {
          status: spy(code: 202),
          parse: {"data" => [{"code" => "INVALID_DATA", "details" => {"api_name" => "First_Name"}, "status" => "error"}]},
        })

        allow(client).to receive(:post).and_return(fake_response)

        expect { client.upsert({}, module_name: "Contacts") }.to raise_error(ZohoCRM::API::APIRequestError) do |error|
          expect(error.error_code).to eq("INVALID_DATA")
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
          status: spy(code: 202),
          parse: {"data" => [{"code" => "INVALID_DATA", "details" => {"api_name" => "First_Name"}, "status" => "error"}]},
        })

        allow(client).to receive(:delete).and_return(fake_response)

        expect { client.destroy("42", module_name: "Contacts") }.to raise_error(ZohoCRM::API::APIRequestError) do |error|
          expect(error.error_code).to eq("INVALID_DATA")
          expect(error.details).to eq({"api_name" => "First_Name"})
          expect(error.status_code).to eq(202)
          expect(error.response).to eq(fake_response)
        end
      end
    end
  end
end
