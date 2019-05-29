# frozen_string_literal: true

RSpec.describe ZohoCRM::API::OAuth do
  describe ZohoCRM::API::OAuth::Error do
    it { is_expected.to have_attr_reader(:token) }

    it "inherits from ZohoCRM::API::Error" do
      expect(described_class.superclass).to be(ZohoCRM::API::Error)
    end

    context "when a token is provided" do
      it "sets the `token' attribute" do
        error = described_class.new(token: "1234")

        expect(error.token).to eq("1234")
      end
    end
  end

  describe ZohoCRM::API::OAuth::RequestError do
    it "inherits from ZohoCRM::API::HTTPRequestError" do
      expect(described_class.superclass).to be(ZohoCRM::API::HTTPRequestError)
    end
  end
end
