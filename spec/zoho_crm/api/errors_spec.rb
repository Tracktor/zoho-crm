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
    it "inherits from ZohoCRM::API::HTTPRequestError" do
      expect(described_class.superclass).to be(ZohoCRM::API::HTTPRequestError)
    end

    it "has a `code' readonly attribute" do
      expect(described_class.new(response: spy)).to have_attr_reader(:code)
    end
  end
end
