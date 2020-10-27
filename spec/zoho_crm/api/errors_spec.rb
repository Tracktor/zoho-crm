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

    describe ".build" do
      it "requires an error code and a status code as attributes", aggregate_failures: true do
        expect { described_class.build }
          .to raise_error(ArgumentError, "missing keywords: error_code, details, status_code, response")

        expect { described_class.build(details: {}, status_code: 202, response: spy) }
          .to raise_error(ArgumentError, "missing keyword: error_code")

        expect { described_class.build(error_code: "INVALID_DATA", status_code: 202, response: spy) }
          .to raise_error(ArgumentError, "missing keyword: details")

        expect { described_class.build(error_code: "INVALID_DATA", details: {}, response: spy) }
          .to raise_error(ArgumentError, "missing keyword: status_code")

        expect { described_class.build(error_code: "INVALID_DATA", details: {}, status_code: 202) }
          .to raise_error(ArgumentError, "missing keyword: response")
      end

      it "returns an instance of #{described_class}" do
        error = described_class.build(error_code: "ERROR", details: {}, status_code: 400, response: spy)

        expect(error).to be_an_instance_of(described_class)
      end

      context "when the error code is \"INVALID_DATA\"" do
        context "when the `details` Hash doesn't contain the \"api_name\" key" do
          it "raises an error" do
            error = described_class.build(error_code: "INVALID_DATA", details: {}, status_code: 202, response: spy)

            expect(error).to be_an_instance_of(ZohoCRM::API::InvalidDataError)
          end
        end

        it "returns an instance of ZohoCRM::API::InvalidDataError" do
          error = described_class.build(error_code: "INVALID_DATA", details: {"api_name" => "Id"}, status_code: 202, response: spy)

          expect(error).to be_an_instance_of(ZohoCRM::API::InvalidDataError)
        end
      end

      context "when the error code is \"DUPLICATE_DATA\"" do
        context "when the `details` Hash doesn't contain the \"api_name\" key" do
          it "raises an error" do
            expect { described_class.build(error_code: "DUPLICATE_DATA", details: {}, status_code: 202, response: spy) }
              .to raise_error(KeyError)
          end
        end

        it "returns an instance of ZohoCRM::API::DuplicateDataError" do
          error = described_class.build(error_code: "DUPLICATE_DATA", details: {"api_name" => "Id"}, status_code: 202, response: spy)

          expect(error).to be_an_instance_of(ZohoCRM::API::DuplicateDataError)
        end
      end
    end

    describe "#initialize" do
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

        it "uses it as error message" do
          expect(error.message).to eq("Invalid data")
        end
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

  describe ZohoCRM::API::InvalidDataError do
    it "inherits from ZohoCRM::API::APIRequestError" do
      expect(described_class.superclass).to be(ZohoCRM::API::APIRequestError)
    end

    context "when the error code is not \"INVALID_DATA\"" do
      it "raises an error" do
        expect { described_class.build(error_code: "ERROR", details: {"api_name" => "Id"}, status_code: 202, response: spy) }
          .to raise_error(ZohoCRM::API::Error, "expected error_code to be \"INVALID_DATA\" but got \"ERROR\"")
      end
    end

    context "when the `details` Hash doesn't contain the \"api_name\" key" do
      it "raises an error" do
        error = described_class.build(error_code: "INVALID_DATA", details: {}, status_code: 202, response: spy)

        expect(error).to have_attributes(
          field_name: nil
        )
      end
    end

    context "when the `details` Hash doesn't contain the \"api_name\" key and have a message" do
      let(:error_message) { "I'm an error message" }
      it "raises an error" do
        error = described_class.build(error_message, error_code: "INVALID_DATA", details: {}, status_code: 202, response: spy)

        expect(error).to have_attributes(
          message: error_message,
          field_name: nil
        )
      end
    end

    context "when no message is passed as argument and `details` Hash contain an \"api_name\" key" do
      let(:api_name) { "Account_Name" }
      let(:error) do
        described_class.new(
          error_code: "INVALID_DATA",
          details: {"api_name" => api_name},
          status_code: 202,
          response: spy
        )
      end

      it "generates an error message" do
        expect(error).to have_attributes(
          message: "Zoho CRM API error -- code: \"INVALID_DATA\" - HTTP status code: 202 - Invalid data for field: \"Account_Name\"",
          field_name: api_name
        )
      end
    end
  end

  describe ZohoCRM::API::DuplicateDataError do
    it "inherits from ZohoCRM::API::APIRequestError" do
      expect(described_class.superclass).to be(ZohoCRM::API::APIRequestError)
    end

    context "when the error code is not \"DUPLICATE_DATA\"" do
      it "raises an error" do
        expect { described_class.build(error_code: "ERROR", details: {"api_name" => "Id"}, status_code: 202, response: spy) }
          .to raise_error(ZohoCRM::API::Error, "expected error_code to be \"DUPLICATE_DATA\" but got \"ERROR\"")
      end
    end

    context "when the `details` Hash doesn't contain the \"api_name\" key" do
      it "raises an error" do
        expect { described_class.build(error_code: "DUPLICATE_DATA", details: {}, status_code: 202, response: spy) }
          .to raise_error(KeyError)
      end
    end

    context "when no message is passed as argument" do
      let(:error) do
        described_class.new(
          error_code: "DUPLICATE_DATA",
          details: {"api_name" => "Account_Name"},
          status_code: 202,
          response: spy
        )
      end

      it "generates an error message" do
        expect(error.message).to eq("Duplicate data for field: \"Account_Name\"")
      end
    end
  end
end
