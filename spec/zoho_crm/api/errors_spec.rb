# frozen_string_literal: true

RSpec.describe ZohoCRM::API do
  describe ZohoCRM::API::Error do
    it "inherits from StandardError" do
      expect(described_class.superclass).to be(StandardError)
    end
  end

  describe ZohoCRM::API::ConfigurationError do
    it "inherits from ZohoCRM::API::Error" do
      expect(described_class.superclass).to be(ZohoCRM::API::Error)
    end
  end

  describe ZohoCRM::API::HTTPError do
    it "inherits from ZohoCRM::API::Error" do
      expect(described_class.superclass).to be(ZohoCRM::API::Error)
    end
  end

  describe ZohoCRM::API::HTTPTimeoutError do
    it "inherits from ZohoCRM::API::HTTPError" do
      expect(described_class.superclass).to be(ZohoCRM::API::HTTPError)
    end
  end

  describe ZohoCRM::API::HTTPRequestError do
    it "inherits from ZohoCRM::API::HTTPError" do
      expect(described_class.superclass).to be(ZohoCRM::API::HTTPError)
    end

    it "requires a response as argument" do
      expect { described_class.new }.to raise_error(ArgumentError, "missing keyword: response")
    end

    it "has a `response' readonly attribute" do
      expect(described_class.new(response: spy)).to have_attr_reader(:response)
    end

    it "sets the response attribute" do
      response = spy("Response")
      error = described_class.new(response: response)

      expect(error.response).to eq(response)
    end
  end

  describe ZohoCRM::API::APIRequestError do
    it "inherits from ZohoCRM::API::Error" do
      expect(described_class.superclass).to be(ZohoCRM::API::Error)
    end

    it "requires an error code and a status code as attributes", aggregate_failures: true do
      expect { described_class.new }.to raise_error(ArgumentError, "missing keywords: error_code, status_code")
      expect { described_class.new(error_code: "INVALID_DATA") }.to raise_error(ArgumentError, "missing keyword: status_code")
      expect { described_class.new(status_code: 400) }.to raise_error(ArgumentError, "missing keyword: error_code")
    end

    context "when a message is passed as argument" do
      subject(:error) { described_class.new("Invalid data", error_code: "INVALID_DATA", status_code: 400) }

      it "generates a default error message" do
        expect(error.message).to eq("Invalid data")
      end
    end

    context "when no message is passed as argument" do
      subject(:error) { described_class.new(error_code: "INVALID_DATA", status_code: 400) }

      it "generates a default error message" do
        expect(error.message).to eq("Zoho CRM API error -- code: \"INVALID_DATA\" - HTTP status code: 400")
      end
    end

    it "has a `error_code' readonly attribute" do
      expect(described_class.new(error_code: "", status_code: 0)).to have_attr_reader(:error_code)
    end

    it "has a `status_code' readonly attribute" do
      expect(described_class.new(error_code: "", status_code: 0)).to have_attr_reader(:status_code)
    end
  end
end
