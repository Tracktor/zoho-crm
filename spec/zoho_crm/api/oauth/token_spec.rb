# frozen_string_literal: true

require "securerandom"

RSpec.describe ZohoCRM::API::OAuth::Token do
  describe "Attributes" do
    it { is_expected.to have_attr_accessor(:access_token) }
    it { is_expected.to have_attr_accessor(:refresh_token) }
    it { is_expected.to have_attr_accessor(:expires_in_sec) }
    it { is_expected.to have_attr_accessor(:expires_in) }
    it { is_expected.to have_attr_accessor(:api_domain) }
    it { is_expected.to have_attr_accessor(:refresh_time) }
  end

  describe ".from_json" do
    let(:attributes) do
      {
        "access_token" => SecureRandom.hex,
        "refresh_token" => SecureRandom.hex,
        "expires_in_sec" => 3600,
        "expires_in" => 3600000,
        "token_type" => "Bearer",
        "api_domain" => "example.com",
      }
    end

    it "returns an instance of #{described_class}" do
      expect(described_class.from_json("{}")).to be_an_instance_of(described_class)
    end

    it "parses the JSON string and builds a token with the provided attributes" do
      json_string = JSON.fast_generate(attributes)

      expect(described_class.from_json(json_string))
        .to have_attributes(attributes)
    end
  end

  describe "#initialize" do
    let(:attributes) do
      {
        "access_token" => SecureRandom.hex,
        "refresh_token" => SecureRandom.hex,
        "expires_in_sec" => 3600,
        "expires_in" => 3600000,
        "token_type" => "Bearer",
        "api_domain" => "example.com",
        "refresh_time" => Time.now - 1000,
      }
    end

    it "accepts a Hash of attributes as argument" do
      expect(described_class.new(attributes)).to have_attributes(attributes)
    end

    it "only recognize String keys from the attributes argument" do
      token = described_class.new({token_type: "code"})

      expect(token.token_type).to be_nil
    end
  end

  describe "#expired?" do
    context "when the access token is missing" do
      subject(:token) do
        described_class.new({
          "access_token" => "",
          "expires_in_sec" => 3600,
          "expires_in" => 3600000,
          "refresh_time" => Time.now - 1000,
        })
      end

      it "returns true" do
        expect(token.expired?).to be(true)
      end
    end

    context "when the the `expires_in_sec' attribute is missing" do
      subject(:token) do
        described_class.new({
          "access_token" => SecureRandom.hex,
          "expires_in_sec" => nil,
          "expires_in" => nil,
          "refresh_time" => Time.now - 1000,
        })
      end

      it "returns true" do
        expect(token.expired?).to be(true)
      end
    end

    context "when the the `refresh_time' attribute is missing" do
      subject(:token) do
        described_class.new({
          "access_token" => SecureRandom.hex,
          "expires_in_sec" => 3600,
          "expires_in" => 3600000,
          "refresh_time" => nil,
        })
      end

      it "returns true" do
        expect(token.expired?).to be(true)
      end
    end

    context "when the token is expired" do
      subject(:token) do
        described_class.new({
          "access_token" => SecureRandom.hex,
          "expires_in_sec" => 3600,
          "expires_in" => 3600000,
          "refresh_time" => Time.now.utc - 4000,
        })
      end

      it "returns true" do
        expect(token.expired?).to be(true)
      end
    end

    context "when the token is not expired" do
      subject(:token) do
        described_class.new({
          "access_token" => SecureRandom.hex,
          "expires_in_sec" => 3600,
          "expires_in" => 3600000,
          "refresh_time" => Time.now.utc - 1000,
        })
      end

      it "returns false" do
        expect(token.expired?).to be(false)
      end
    end
  end

  describe "#access_token=" do
    context "when the given value is nil" do
      subject(:token) { described_class.new }

      it "sets the `access_token' attribute to `nil`" do
        token.access_token = nil

        expect(token.access_token).to be_nil
      end
    end

    context "when the given value is empty" do
      subject(:token) { described_class.new }

      it "sets the `access_token' attribute to `nil`" do
        token.access_token = ""

        expect(token.access_token).to be_nil
      end
    end

    context "when the given value is not nil or empty" do
      subject(:token) { described_class.new }

      it "sets the `access_token' attribute to the given value" do
        token.access_token = "1234"

        expect(token.access_token).to eq("1234")
      end
    end
  end

  describe "#refresh_token=" do
    context "when the given value is nil" do
      subject(:token) { described_class.new }

      it "sets the `refresh_token' attribute to `nil`" do
        token.refresh_token = nil

        expect(token.refresh_token).to be_nil
      end
    end

    context "when the given value is empty" do
      subject(:token) { described_class.new }

      it "sets the `refresh_token' attribute to `nil`" do
        token.refresh_token = ""

        expect(token.refresh_token).to be_nil
      end
    end

    context "when the given value is not nil or empty" do
      subject(:token) { described_class.new }

      it "sets the `refresh_token' attribute to the given value" do
        token.refresh_token = "1234"

        expect(token.refresh_token).to eq("1234")
      end
    end
  end

  describe "#expires_in_sec=" do
    context "when the given value is nil" do
      subject(:token) { described_class.new({"expires_in_sec" => 3600, "expires_in" => 3600000}) }

      it "sets the `expires_in_sec' attribute to nil" do
        token.expires_in_sec = nil

        expect(token.expires_in_sec).to be_nil
      end

      it "updates the `expires_in' attribute" do
        token.expires_in_sec = nil

        expect(token.expires_in).to be_nil
      end
    end

    context "when the given value is not nil" do
      subject(:token) { described_class.new({"expires_in_sec" => 1500, "expires_in" => 1500000}) }

      it "sets the `expires_in_sec' attribute to the given value" do
        token.expires_in_sec = 3600

        expect(token.expires_in_sec).to eq(3600)
      end

      it "converts the value to an Integer" do
        token.expires_in_sec = "3600"

        expect(token.expires_in_sec).to eq(3600)
      end

      it "updates the `expires_in' attribute" do
        token.expires_in_sec = 3600

        expect(token.expires_in).to eq(3600000)
      end
    end
  end

  describe "#expires_in=" do
    context "when the given value is nil" do
      subject(:token) { described_class.new({"expires_in_sec" => 3600, "expires_in" => 3600000}) }

      it "sets the `expires_in' attribute to nil" do
        token.expires_in = nil

        expect(token.expires_in).to be_nil
      end

      it "updates the `expires_in_sec' attribute" do
        token.expires_in = nil

        expect(token.expires_in_sec).to be_nil
      end
    end

    context "when the given value is not nil" do
      subject(:token) { described_class.new }

      it "sets the `expires_in' attribute to the given value" do
        token.expires_in = 3600000

        expect(token.expires_in).to eq(3600000)
      end

      it "converts the value to an Integer" do
        token.expires_in = "3600000"

        expect(token.expires_in).to eq(3600000)
      end

      it "updates the `expires_in_sec' attribute" do
        token.expires_in = 3600000

        expect(token.expires_in_sec).to eq(3600)
      end
    end
  end

  describe "#token_type=" do
    context "when the given value is nil" do
      subject(:token) { described_class.new }

      it "sets the `token_type' attribute to `nil`" do
        token.token_type = nil

        expect(token.token_type).to be_nil
      end
    end

    context "when the given value is empty" do
      subject(:token) { described_class.new }

      it "sets the `token_type' attribute to `nil`" do
        token.token_type = ""

        expect(token.token_type).to be_nil
      end
    end

    context "when the given value is not nil or empty" do
      subject(:token) { described_class.new }

      it "sets the `token_type' attribute to the given value" do
        token.token_type = "Bearer"

        expect(token.token_type).to eq("Bearer")
      end
    end
  end

  describe "#api_domain=" do
    context "when the given value is nil" do
      subject(:token) { described_class.new }

      it "sets the `api_domain' attribute to `nil`" do
        token.api_domain = nil

        expect(token.api_domain).to be_nil
      end
    end

    context "when the given value is empty" do
      subject(:token) { described_class.new }

      it "sets the `api_domain' attribute to `nil`" do
        token.api_domain = ""

        expect(token.api_domain).to be_nil
      end
    end

    context "when the given value is not nil or empty" do
      subject(:token) { described_class.new }

      it "sets the `api_domain' attribute to the given value" do
        token.api_domain = "example.com"

        expect(token.api_domain).to eq("example.com")
      end
    end
  end

  describe "#refresh_time=" do
    subject(:token) { described_class.new }

    context "when the given value is an instance of Time" do
      it "sets the `refresh_time' attribute to the given value in UTC" do
        skip "timezones"

        refresh_time     = Time.new(2008, 6, 21, 10, 30, 0).localtime("+02:00")
        refresh_time_utc = Time.utc(2008, 6, 21, 10, 30, 0)
        token.refresh_time = refresh_time

        expect(token.refresh_time).to eq(refresh_time_utc)
      end
    end

    context "when the given value is an instance of Date" do
      it "sets the `refresh_time' attribute to the given value converted to a Time in UTC" do
        skip "timezones..."

        refresh_date = Date.new(2001, 2, 3)
        refresh_time = Time.utc(2001, 2, 3, 3, 0, 0)
        token.refresh_time = refresh_date

        expect(token.refresh_time).to eq(refresh_time)
      end
    end

    context "when the given value is an instance of DateTime" do
      it "sets the `refresh_time' attribute to the given value converted to a Time in UTC" do
        skip "timezones..."

        refresh_datetime = DateTime.new(2001, 2, 3, 4, 5, 6, "+2")
        refresh_time     =     Time.utc(2001, 2, 3, 4, 5, 6)
        token.refresh_time = refresh_datetime

        expect(token.refresh_time).to eq(refresh_time)
      end
    end

    context "when the given value is an instance of Integer" do
      it "sets the `refresh_time' attribute to the given value converted to a Time in UTC" do
        refresh_timestamp = 1214037000 # Time.new(2008, 6, 21, 10, 30, 0).localtime("+02:00").to_i
        refresh_time = Time.utc(2008, 6, 21, 8, 30, 0)
        token.refresh_time = refresh_timestamp

        expect(token.refresh_time).to eq(refresh_time)
      end
    end

    context "when the given value is an instance of String" do
      it "sets the `refresh_time' attribute to the given value converted to a Time in UTC" do
        refresh_timestring = "2008-06-21T10:30:00+02:00" # Time.new(2008, 6, 21, 10, 30, 0).localtime("+02:00").iso8601
        refresh_time = Time.utc(2008, 6, 21, 8, 30, 0)
        token.refresh_time = refresh_timestring

        expect(token.refresh_time).to eq(refresh_time)
      end
    end

    context "when the given value is nil" do
      it "sets the `refresh_time' attribute to nil" do
        token.refresh_time = nil

        expect(token.refresh_time).to be_nil
      end
    end

    context "when the given value can't be converted to a Time" do
      it "raises an error" do
        expect { token.refresh_time = {time: 42} }.to raise_error(TypeError, "no implicit conversion of Hash into Time")
      end
    end
  end

  describe "#to_h" do
    let(:attributes) do
      {
        "access_token" => SecureRandom.hex,
        "refresh_token" => SecureRandom.hex,
        "expires_in_sec" => 3600,
        "expires_in" => 3600000,
        "token_type" => "Bearer",
        "api_domain" => "example.com",
      }
    end

    let(:token) do
      described_class.new(attributes).tap do |t|
        t.refresh_time = Time.now
      end
    end

    it "returns a Hash representation of the token" do
      expect(token.to_h).to eq(attributes)
    end

    it "is aliased as #to_hash" do
      expect(token.method(:to_hash)).to eql(token.method(:to_h))
    end
  end

  describe "#from_json" do
    subject(:token) { described_class.new }

    let(:attributes) do
      {
        "access_token" => SecureRandom.hex,
        "refresh_token" => SecureRandom.hex,
        "expires_in_sec" => 3600,
        "expires_in" => 3600000,
        "token_type" => "Bearer",
        "api_domain" => "example.com",
      }
    end

    it "returns self" do
      expect(token.from_json("{}")).to eq(token)
    end

    it "parses the JSON string and updates the token attributes" do
      json_string = JSON.fast_generate(attributes)

      expect { token.from_json(json_string) }
        .to change { token.access_token }.to(attributes["access_token"])
        .and change { token.refresh_token }.to(attributes["refresh_token"])
        .and change { token.expires_in_sec }.to(attributes["expires_in_sec"])
        .and change { token.expires_in }.to(attributes["expires_in"])
        .and change { token.token_type }.to(attributes["token_type"])
        .and change { token.api_domain }.to(attributes["api_domain"])
    end

    it "parses the JSON string and builds a token with the provided attributes" do
      expect(described_class.from_json(JSON.fast_generate(attributes)))
        .to have_attributes(attributes)
    end
  end

  describe "#to_json" do
    let(:attributes) do
      {
        "access_token" => SecureRandom.hex,
        "refresh_token" => SecureRandom.hex,
        "expires_in_sec" => 3600,
        "expires_in" => 3600000,
        "token_type" => "Bearer",
        "api_domain" => "example.com",
      }
    end

    let(:token) { described_class.new(attributes) }

    it "returns a JSON string" do
      expect(token.to_json).to eq(JSON.dump(attributes))
    end
  end
end
