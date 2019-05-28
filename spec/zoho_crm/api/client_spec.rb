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
      allow(client).to receive(:get)

      client.show(42, module_name: "Contacts")

      expect(client).to have_received(:get).with("Contacts/42")
    end
  end

  describe "#create" do
    subject(:client) { described_class.new(spy) }

    it "requires a record ID and a module name", aggregate_failures: true do
      expect { client.create }.to raise_error(ArgumentError, "wrong number of arguments (given 0, expected 1; required keyword: module_name)")
      expect { client.create(42, {}) }.to raise_error(ArgumentError, "missing keyword: module_name")
    end

    it "performs a POST request" do
      allow(client).to receive(:post)

      client.create({}, module_name: "Contacts")

      expect(client).to have_received(:post).with("Contacts", body: {data: [{}]})
    end

    it "can create multiple records with a single POST request" do
      allow(client).to receive(:post)

      client.create([{name: "John"}, {name: "Jane"}], module_name: "Contacts")

      expect(client).to have_received(:post).once.with("Contacts", body: {data: [{name: "John"}, {name: "Jane"}]})
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
      allow(client).to receive(:put)

      client.update(42, {}, module_name: "Contacts")

      expect(client).to have_received(:put).with("Contacts/42", body: {data: [{}]})
    end
  end

  describe "#upsert" do
    subject(:client) { described_class.new(spy) }

    it "requires a record ID and a module name", aggregate_failures: true do
      expect { client.upsert }.to raise_error(ArgumentError, "wrong number of arguments (given 0, expected 1; required keyword: module_name)")
      expect { client.upsert(42) }.to raise_error(ArgumentError, "missing keyword: module_name")
    end

    it "performs a POST request" do
      allow(client).to receive(:post)

      client.upsert([{}], module_name: "Contacts")

      expect(client).to have_received(:post).with("Contacts/upsert", body: {data: [{}], duplicate_check_fields: ""})
    end

    it "can upsert multiple records with a single POST request" do
      allow(client).to receive(:post)

      client.upsert([{name: "John"}, {name: "Jane"}], module_name: "Contacts")

      expect(client).to have_received(:post).once.with("Contacts/upsert", body: {
        data: [{name: "John"}, {name: "Jane"}],
        duplicate_check_fields: "",
      })
    end

    it "accepts a list of fields to check for existing records" do
      allow(client).to receive(:post)

      client.upsert([{}], module_name: "Contacts", duplicate_check_fields: %w[email last_name])

      expect(client).to have_received(:post).with("Contacts/upsert", body: {
        data: [{}],
        duplicate_check_fields: "email,last_name",
      })
    end
  end

  describe "#destroy" do
    subject(:client) { described_class.new(spy) }

    it "requires a record ID and a module name", aggregate_failures: true do
      expect { client.destroy }.to raise_error(ArgumentError, "wrong number of arguments (given 0, expected 1; required keyword: module_name)")
      expect { client.destroy(42) }.to raise_error(ArgumentError, "missing keyword: module_name")
    end

    it "performs a DELETE request" do
      allow(client).to receive(:delete)

      client.destroy(42, module_name: "Contacts")

      expect(client).to have_received(:delete).with("Contacts/42")
    end
  end
end
