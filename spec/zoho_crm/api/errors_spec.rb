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
      expect { described_class.new }
        .to raise_error(ArgumentError, "missing keywords: error_code, details, status_code, response")

      expect { described_class.new(details: {}, status_code: 202, response: spy) }
        .to raise_error(ArgumentError, "missing keyword: error_code")

      expect { described_class.new(error_code: "INVALID_DATA", status_code: 202, response: spy) }
        .to raise_error(ArgumentError, "missing keyword: details")

      expect { described_class.new(error_code: "INVALID_DATA", details: {}, response: spy) }
        .to raise_error(ArgumentError, "missing keyword: status_code")

      expect { described_class.new(error_code: "INVALID_DATA", details: {}, status_code: 202) }
        .to raise_error(ArgumentError, "missing keyword: response")
    end

    context "when a message is passed as argument" do
      subject(:error) do
        described_class.new(
          "Invalid data",
          error_code: "INVALID_DATA",
          details: {},
          status_code: 400,
          response: spy
        )
      end

      it "generates a default error message" do
        expect(error.message).to eq("Invalid data")
      end
    end

    context "when no message is passed as argument" do
      context "when the error details include a field name" do
        let(:error) do
          described_class.new(
            error_code: "INVALID_DATA",
            details: {"api_name" => "Account_Name"},
            status_code: 202,
            response: spy
          )
        end

        it "generates an error message including the field name" do
          expect(error.message).to eq("Zoho CRM API error -- code: \"INVALID_DATA\" - HTTP status code: 202 - Field API Name: \"Account_Name\"")
        end
      end

      context "when the error details don't include a field name" do
        let(:error) do
          described_class.new(
            error_code: "INVALID_DATA",
            details: {},
            status_code: 400,
            response: spy
          )
        end

        it "generates an error message" do
          expect(error.message).to eq("Zoho CRM API error -- code: \"INVALID_DATA\" - HTTP status code: 400")
        end
      end
    end

    it "has a `error_code' readonly attribute" do
      expect(described_class.new(error_code: "", details: {}, status_code: 0, response: spy)).to have_attr_reader(:error_code)
    end

    it "has a `details' readonly attribute" do
      expect(described_class.new(error_code: "", details: {}, status_code: 0, response: spy)).to have_attr_reader(:details)
    end

    it "has a `status_code' readonly attribute" do
      expect(described_class.new(error_code: "", details: {}, status_code: 0, response: spy)).to have_attr_reader(:status_code)
    end

    it "has a `response' readonly attribute" do
      expect(described_class.new(error_code: "", details: {}, status_code: 0, response: spy)).to have_attr_reader(:response)
    end
  end
end
