# frozen_string_literal: true

RSpec.describe ZohoCRM::API do
  describe ".http_client" do
    it "returns an HTTP::Client" do
      expect(described_class.http_client).to be_an_instance_of(HTTP::Client)
    end
  end
end
