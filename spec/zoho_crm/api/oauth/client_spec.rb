# frozen_string_literal: true

require "securerandom"

RSpec.describe ZohoCRM::API::OAuth::Client do
  # Stub all HTTP requests
  before { allow_any_instance_of(described_class).to receive(:http).and_return(spy) }

  describe "Attributes" do
    it { is_expected.to have_attr_reader(:token) }
    it { is_expected.to have_attr_reader(:config) }
  end

  describe "#initialize" do
    it "assigns a new token to the `token' attribute" do
      client = described_class.new

      expect(client.token).to be_an_instance_of(ZohoCRM::API::OAuth::Token)
    end

    context "when token attributes are given" do
      it "assigns a token with the given attributes to the `token' attribute" do
        client = described_class.new({"access_token" => "1234"})

        expect(client.token.access_token).to eq("1234")
      end
    end

    context "when an env name is passed as an argument" do
      it "uses the configuration associated with the env" do
        client = described_class.new(env: :beta)

        expect(client.config).to eql(ZohoCRM::API.config(:beta))
      end
    end

    context "when no env name is passed as an argument" do
      it "uses the default configuration" do
        client = described_class.new

        expect(client.config).to eql(ZohoCRM::API.config(:default))
      end
    end
  end

  describe "#authorize_url" do
    subject(:client) { described_class.new }

    # Stub the config
    before do
      allow(ZohoCRM::API.config).to receive(:client_id).and_return("12345")
      allow(ZohoCRM::API.config).to receive(:scopes).and_return(%w[ZohoCRM.users.all ZohoCRM.modules.all])
      allow(ZohoCRM::API.config).to receive(:redirect_url).and_return("http://example.com/zoho/auth")
    end

    context "when the region is com" do
      before do
        allow(ZohoCRM::API.config).to receive(:region).and_return("com")
        allow(ZohoCRM::API.config).to receive(:accounts_url).and_return("https://accounts.zoho.com")
      end

      it "returns the URL of the Zoho authorization endpoint" do
        encoded_url = "https://accounts.zoho.com/oauth/v2/auth?client_id=12345&scope=ZohoCRM.users.all%2CZohoCRM.modules.all&response_type=code&redirect_uri=http%3A%2F%2Fexample.com%2Fzoho%2Fauth&access_type=offline&prompt=consent"

        expect(client.authorize_url).to eq(encoded_url)
      end
    end

    context "when the region is eu" do
      before do
        allow(ZohoCRM::API.config).to receive(:region).and_return("eu")
        allow(ZohoCRM::API.config).to receive(:accounts_url).and_return("https://accounts.zoho.eu")
      end

      it "returns the URL of the Zoho authorization endpoint in the .com region" do
        encoded_url = "https://accounts.zoho.com/oauth/v2/auth?client_id=12345&scope=ZohoCRM.users.all%2CZohoCRM.modules.all&response_type=code&redirect_uri=http%3A%2F%2Fexample.com%2Fzoho%2Fauth&access_type=offline&prompt=consent"

        expect(client.authorize_url).to eq(encoded_url)
      end
    end

    context "when the region is in" do
      before do
        allow(ZohoCRM::API.config).to receive(:region).and_return("in")
        allow(ZohoCRM::API.config).to receive(:accounts_url).and_return("https://accounts.zoho.in")
      end

      it "returns the URL of the Zoho authorization endpoint in the .com region" do
        encoded_url = "https://accounts.zoho.com/oauth/v2/auth?client_id=12345&scope=ZohoCRM.users.all%2CZohoCRM.modules.all&response_type=code&redirect_uri=http%3A%2F%2Fexample.com%2Fzoho%2Fauth&access_type=offline&prompt=consent"

        expect(client.authorize_url).to eq(encoded_url)
      end
    end

    context "when the region is eu" do
      it "returns the URL of the Zoho authorization endpoint in the .com region" do
        encoded_url = "https://accounts.zoho.com/oauth/v2/auth?client_id=12345&scope=ZohoCRM.users.all%2CZohoCRM.modules.all&response_type=code&redirect_uri=http%3A%2F%2Fexample.com%2Fzoho%2Fauth&access_type=offline&prompt=consent"

        expect(client.authorize_url).to eq(encoded_url)
      end
    end
  end

  describe "#create" do
    it "requires a grant token as argument" do
      expect { described_class.new.create }.to raise_error(ArgumentError, "missing keyword: grant_token")
    end

    describe "HTTP request" do
      subject(:client) { described_class.new }

      before do
        # Stub the config
        allow(ZohoCRM::API.config).to receive(:accounts_url).and_return("https://accounts.zoho.eu")
        allow(ZohoCRM::API.config).to receive(:client_id).and_return("12345")
        allow(ZohoCRM::API.config).to receive(:client_secret).and_return("XXXXX")
        allow(ZohoCRM::API.config).to receive(:redirect_url).and_return("http://example.com/zoho/auth")
      end

      it "performs a POST request" do
        # Stub the HTTP request/response
        response = spy("Response", status: spy(success?: true), parse: {})
        allow(client.http).to receive(:post).and_return(response)

        grant_token = SecureRandom.hex

        client.create(grant_token: grant_token)

        expect(client.http).to have_received(:post).with("https://accounts.zoho.eu/oauth/v2/token", form: {
          grant_type: "authorization_code",
          code: grant_token,
          client_id: "12345",
          client_secret: "XXXXX",
          redirect_uri: "http://example.com/zoho/auth",
        })
      end

      context "when the request succeeds" do
        let(:token_attributes) do
          {
            "access_token" => SecureRandom.hex,
            "refresh_token" => SecureRandom.hex,
            "expires_in_sec" => 3600,
            "expires_in" => 3600000,
            "token_type" => "Bearer",
            "api_domain" => "example.com",
          }
        end

        let(:response) { spy("Response", status: spy(success?: true), parse: token_attributes) }

        before do
          allow(client.http).to receive(:post).and_return(response)
        end

        it "returns token" do
          token = client.create(grant_token: "123456")

          expect(token).to eq(client.token)
        end

        it "updates the token attributes" do
          refresh_time     = Time.new(2008, 6, 21, 12, 30, 0, "+02:00")
          refresh_time_utc = Time.new(2008, 6, 21, 10, 30, 0, "+00:00")

          allow(Time).to receive(:now).and_return(refresh_time)

          expect { client.create(grant_token: "123456") }
            .to  change(client.token, :access_token).to(token_attributes["access_token"])
            .and change(client.token, :refresh_token).to(token_attributes["refresh_token"])
            .and change(client.token, :expires_in_sec).to(token_attributes["expires_in_sec"])
            .and change(client.token, :expires_in).to(token_attributes["expires_in"])
            .and change(client.token, :token_type).to(token_attributes["token_type"])
            .and change(client.token, :api_domain).to(token_attributes["api_domain"])
            .and change(client.token, :refresh_time).to(refresh_time_utc)
        end
      end

      context "when the request fails" do
        let(:response) { spy("Response", status: spy(success?: false, reason: "")) }

        before do
          allow(client.http).to receive(:post).and_return(response)
        end

        it "raises an error", aggregate_failures: true do
          expect { client.create(grant_token: "123456") }.to raise_error(ZohoCRM::API::OAuth::RequestError) do |error|
            expect(error.message).to eq("Failed to generate and access token and a refresh token")
            expect(error.response).to eq(response)
          end
        end
      end
    end
  end

  describe "#refresh" do
    context "when the client is not authorized" do
      subject(:client) { described_class.new }

      it "raises an error", aggregate_failures: true do
        expect { client.refresh }.to raise_error(ZohoCRM::API::OAuth::Error) do |error|
          expect(error.message).to eq("The client needs to be authorized to generate a new access token")
          expect(error.token).to eq(client.token)
        end
      end
    end

    context "when the client is authorized" do
      before do
        # Stub the config
        allow(ZohoCRM::API.config).to receive(:accounts_url).and_return("https://accounts.zoho.eu")
        allow(ZohoCRM::API.config).to receive(:client_id).and_return("12345")
        allow(ZohoCRM::API.config).to receive(:client_secret).and_return("XXXXX")
        allow(ZohoCRM::API.config).to receive(:redirect_url).and_return("http://example.com/zoho/auth")
      end

      it "performs a POST request" do
        refresh_token = SecureRandom.hex
        client = described_class.new({"refresh_token" => refresh_token})

        # Stub the HTTP request/response
        response = spy("Response", status: spy(success?: true), parse: {})
        allow(client.http).to receive(:post).and_return(response)

        client.refresh

        expect(client.http).to have_received(:post).with("https://accounts.zoho.eu/oauth/v2/token", form: {
          grant_type: "refresh_token",
          refresh_token: refresh_token,
          client_id: "12345",
          client_secret: "XXXXX",
          redirect_uri: "http://example.com/zoho/auth",
        })
      end

      context "when the request succeeds" do
        subject(:client) { described_class.new({"refresh_token" => SecureRandom.hex}) }

        let(:token_attributes) do
          {
            "access_token" => SecureRandom.hex,
            "expires_in_sec" => 3600,
            "expires_in" => 3600000,
            "token_type" => "Bearer",
            "api_domain" => "example.com",
          }
        end

        let(:response) { spy("Response", status: spy(success?: true), parse: token_attributes) }

        before do
          allow(client.http).to receive(:post).and_return(response)
        end

        it "returns token" do
          token = client.refresh

          expect(token).to eq(client.token)
        end

        it "updates the token attributes" do
          refresh_time     = Time.new(2008, 6, 21, 12, 30, 0, "+02:00")
          refresh_time_utc = Time.new(2008, 6, 21, 10, 30, 0, "+00:00")

          allow(Time).to receive(:now).and_return(refresh_time)

          expect { client.refresh }
            .to  change(client.token, :access_token).to(token_attributes["access_token"])
            .and change(client.token, :expires_in_sec).to(token_attributes["expires_in_sec"])
            .and change(client.token, :expires_in).to(token_attributes["expires_in"])
            .and change(client.token, :token_type).to(token_attributes["token_type"])
            .and change(client.token, :api_domain).to(token_attributes["api_domain"])
            .and change(client.token, :refresh_time).to(refresh_time_utc)
        end

        it "doesn't update the refresh token" do
          expect { client.refresh }.to_not change(client.token, :refresh_token)
        end
      end

      context "when the request fails" do
        subject(:client) { described_class.new({"refresh_token" => SecureRandom.hex}) }

        let(:response) { spy("Response", status: spy(success?: false, reason: "")) }

        before do
          allow(client.http).to receive(:post).and_return(response)
        end

        it "raises an error", aggregate_failures: true do
          expect { client.refresh }.to raise_error(ZohoCRM::API::OAuth::RequestError) do |error|
            expect(error.message).to eq("Failed to refresh the access token")
            expect(error.response).to eq(response)
          end
        end
      end
    end
  end

  describe "#revoke" do
    context "when the client is not authorized" do
      subject(:client) { described_class.new }

      it "raises an error", aggregate_failures: true do
        expect { client.revoke }.to raise_error(ZohoCRM::API::OAuth::Error) do |error|
          expect(error.message).to eq("The client needs to be authorized to revoke the refresh token")
          expect(error.token).to eq(client.token)
        end
      end
    end

    context "when the client is authorized" do
      before do
        # Stub the config
        allow(ZohoCRM::API.config).to receive(:accounts_url).and_return("https://accounts.zoho.eu")
        allow(ZohoCRM::API.config).to receive(:client_id).and_return("12345")
        allow(ZohoCRM::API.config).to receive(:client_secret).and_return("XXXXX")
        allow(ZohoCRM::API.config).to receive(:redirect_url).and_return("http://example.com/zoho/auth")
      end

      it "performs a POST request" do
        refresh_token = SecureRandom.hex
        client = described_class.new({"refresh_token" => refresh_token})

        # Stub the HTTP request/response
        response = spy("Response", status: spy(success?: true), parse: {})
        allow(client.http).to receive(:post).and_return(response)

        client.revoke

        expect(client.http).to have_received(:post).with("https://accounts.zoho.eu/oauth/v2/token/revoke", form: {
          token: refresh_token,
          client_id: "12345",
          client_secret: "XXXXX",
          redirect_uri: "http://example.com/zoho/auth",
        })
      end

      context "when the request succeeds" do
        subject(:client) do
          described_class.new({
            "access_token" => SecureRandom.hex,
            "refresh_token" => SecureRandom.hex,
            "expires_in_sec" => 3600,
            "expires_in" => 3600000,
            "token_type" => "Bearer",
            "api_domain" => "example.com",
            "refresh_time" => Time.now - 1000,
          })
        end

        let(:response) { spy("Response", status: spy(success?: true)) }

        before do
          allow(client.http).to receive(:post).and_return(response)
        end

        it "returns token" do
          token = client.revoke

          expect(token).to eq(client.token)
        end

        it "revokes the token" do
          expect { client.revoke }
            .to  change(client.token, :access_token).to(nil)
            .and change(client.token, :expires_in_sec).to(nil)
            .and change(client.token, :expires_in).to(nil)
            .and change(client.token, :token_type).to(nil)
            .and change(client.token, :api_domain).to(nil)
            .and change(client.token, :refresh_time).to(nil)
        end
      end

      context "when the request fails" do
        subject(:client) { described_class.new({"refresh_token" => SecureRandom.hex}) }

        let(:response) { spy("Response", status: spy(success?: false, reason: "")) }

        before do
          allow(client.http).to receive(:post).and_return(response)
        end

        it "raises an error", aggregate_failures: true do
          expect { client.revoke }.to raise_error(ZohoCRM::API::OAuth::RequestError) do |error|
            expect(error.message).to eq("Failed to revoke the refresh token")
            expect(error.response).to eq(response)
          end
        end
      end
    end
  end

  describe "#authorized?" do
    context "when the refresh token is present" do
      subject(:client) { described_class.new({"refresh_token" => "1234"}) }

      it "returns true" do
        expect(client.authorized?).to be(true)
      end
    end

    context "when the refresh token is missing" do
      subject(:client) { described_class.new }

      it "returns false" do
        expect(client.authorized?).to be(false)
      end
    end
  end

  describe "#http" do
    subject(:client) { described_class.new }

    # Disable stubs on the method
    before { allow(client).to receive(:http).and_call_original }

    it "returns an HTTP::Client" do
      expect(client.http).to be_an_instance_of(HTTP::Client)
    end

    it "caches the return value" do
      expect(client.http).to eql(client.http)
    end
  end

  describe "#oauth_url" do
    subject(:client) { described_class.new }

    before do
      allow(ZohoCRM::API.config).to receive(:accounts_url).and_return("https://accounts.zoho.eu")
    end

    it "returns the Zoho OAuth base URL" do
      expect(client.oauth_url).to eq("https://accounts.zoho.eu/oauth/v2")
    end
  end

  describe "#token_url" do
    subject(:client) { described_class.new }

    before do
      allow(ZohoCRM::API.config).to receive(:accounts_url).and_return("https://accounts.zoho.eu")
    end

    it "returns the Zoho OAuth token URL" do
      expect(client.token_url).to eq("https://accounts.zoho.eu/oauth/v2/token")
    end
  end
end
