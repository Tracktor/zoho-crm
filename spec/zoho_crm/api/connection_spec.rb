# frozen_string_literal: true

RSpec.describe ZohoCRM::API::Connection do
  # Stub all HTTP requests
  before { allow_any_instance_of(described_class).to receive(:http).and_return(spy) }

  describe "#initialize" do
    it "requires an OAuth client as argument" do
      expect { described_class.new }.to raise_error(ArgumentError, "wrong number of arguments (given 0, expected 1)")
    end

    it "sets the `oauth_client' attribute" do
      oauth_client = spy("OAuthClient")
      connection = described_class.new(oauth_client)

      expect(connection.oauth_client).to eq(oauth_client)
    end
  end

  describe "#get" do
    subject(:connection) { described_class.new(spy) }

    it "requires a URI as argument" do
      expect { connection.get }.to raise_error(ArgumentError, "wrong number of arguments (given 0, expected 1)")
    end

    it "performs a GET request" do
      allow(connection).to receive(:request)

      connection.get("Contacts", headers: {}, query: {})

      expect(connection).to have_received(:request).with(:get, "Contacts", headers: {}, params: {})
    end
  end

  describe "#post" do
    subject(:connection) { described_class.new(spy) }

    it "requires a URI as argument" do
      expect { connection.post }.to raise_error(ArgumentError, "wrong number of arguments (given 0, expected 1)")
    end

    it "performs a POST request" do
      allow(connection).to receive(:request)

      connection.post("Contacts", headers: {}, query: {}, body: {})

      expect(connection).to have_received(:request).with(:post, "Contacts", headers: {}, params: {}, json: {})
    end
  end

  describe "#put" do
    subject(:connection) { described_class.new(spy) }

    it "requires a URI as argument" do
      expect { connection.put }.to raise_error(ArgumentError, "wrong number of arguments (given 0, expected 1)")
    end

    it "performs a PUT request" do
      allow(connection).to receive(:request)

      connection.put("Contacts", headers: {}, query: {}, body: {})

      expect(connection).to have_received(:request).with(:put, "Contacts", headers: {}, params: {}, json: {})
    end
  end

  describe "#patch" do
    subject(:connection) { described_class.new(spy) }

    it "requires a URI as argument" do
      expect { connection.patch }.to raise_error(ArgumentError, "wrong number of arguments (given 0, expected 1)")
    end

    it "performs a PATCH request" do
      allow(connection).to receive(:request)

      connection.patch("Contacts", headers: {}, query: {}, body: {})

      expect(connection).to have_received(:request).with(:patch, "Contacts", headers: {}, params: {}, json: {})
    end
  end

  describe "#delete" do
    subject(:connection) { described_class.new(spy) }

    it "requires a URI as argument" do
      expect { connection.get }.to raise_error(ArgumentError, "wrong number of arguments (given 0, expected 1)")
    end

    it "performs a DELETE request" do
      allow(connection).to receive(:request)

      connection.delete("Contacts", headers: {}, query: {})

      expect(connection).to have_received(:request).with(:delete, "Contacts", headers: {}, params: {})
    end
  end

  describe "#build_url" do
    before do
      allow(ZohoCRM::API.config).to receive(:base_url).and_return("https://www.zohoapis.com/crm/v2")
    end

    it "returns the URL for the given endpoint" do
      connection = described_class.new(spy)

      expect(connection.build_url("Contacts")).to eq("https://www.zohoapis.com/crm/v2/Contacts")
    end
  end

  describe "#request" do
    context "when the OAuth client is not authorized" do
      let(:connection) { described_class.new(spy) }

      before do
        allow(connection.oauth_client).to receive(:authorized?).and_return(false)
      end

      it "raises an error" do
        expect { connection.request("", "") }
          .to raise_error(ZohoCRM::API::OAuth::Error, "The OAuth client is not authorized")
      end
    end

    context "when the OAuth client is authorized" do
      it "requires an HTTP verb and a URI as arguments", aggregate_failures: true do
        connection = described_class.new(spy)

        expect { connection.request }.to raise_error(ArgumentError, "wrong number of arguments (given 0, expected 2)")
        expect { connection.request("") }.to raise_error(ArgumentError, "wrong number of arguments (given 1, expected 2)")
      end

      context "when the OAuth token is expired" do
        subject(:connection) { described_class.new(spy) }

        before do
          allow(connection.oauth_client).to receive(:authorized?).and_return(true)
          allow(connection.oauth_client).to receive_message_chain(:token, :expired?).and_return(true)
        end

        it "refreshes the token" do
          allow(connection.oauth_client).to receive(:refresh)

          connection.request("", "")

          expect(connection.oauth_client).to have_received(:refresh)
        end
      end

      context "when the OAuth token is not expired" do
        subject(:connection) { described_class.new(spy) }

        before do
          allow(connection.oauth_client).to receive(:authorized?).and_return(true)
          allow(connection.oauth_client).to receive_message_chain(:token, :expired?).and_return(false)
        end

        it "doesn't refresh the token" do
          allow(connection.oauth_client).to receive(:refresh)

          connection.request("", "")

          expect(connection.oauth_client).to_not have_received(:refresh)
        end
      end

      describe "HTTP request" do
        subject(:connection) { described_class.new(spy) }

        before do
          allow(connection.oauth_client).to receive(:authorized?).and_return(true)
          allow(connection.oauth_client).to receive_message_chain(:token, :expired?).and_return(false)
        end

        it "makes an HTTP request with the given HTTP verb and URI" do
          verb = :get
          uri = "Contacts"

          allow(connection.http).to receive(:request).and_return(spy)

          connection.request(verb, uri)

          expect(connection.http).to have_received(:request).with(verb, a_string_ending_with(uri), {})
        end

        context "when the request succeeds" do
          let(:response) { spy("Response", status: spy(success?: true)) }

          before do
            allow(connection.http).to receive(:request).and_return(response)
          end

          it "returns the response" do
            expect(connection.request("", "")).to eq(response)
          end
        end

        context "when the request fails" do
          let(:response) { spy("Response", status: spy(success?: false, reason: "")) }

          before do
            allow(connection.http).to receive(:request).and_return(response)
          end

          it "raises an error" do
            expect { connection.request("", "") }.to raise_error(ZohoCRM::API::HTTPRequestError)
          end
        end

        context "when the request fails with a connection error" do
          before do
            allow(connection.http).to receive(:request).and_raise(HTTP::ConnectionError)
          end

          it "raises an error" do
            expect { connection.request("", "") }.to raise_error(ZohoCRM::API::HTTPError)
          end
        end

        context "when the request fails with a timeout error" do
          before do
            allow(connection.http).to receive(:request).and_raise(HTTP::TimeoutError)
          end

          it "raises an error" do
            expect { connection.request("", "") }.to raise_error(ZohoCRM::API::HTTPTimeoutError)
          end
        end
      end
    end
  end

  describe "#http" do
    subject(:connection) { described_class.new(spy) }

    # Disable stubs on the method
    before { allow(connection).to receive(:http).and_call_original }

    it "adds the \"Authorization\" header", aggregate_failures: true do
      expect(connection.http.default_options.headers).to include("Authorization")
      expect(connection.http.default_options.headers["Authorization"])
        .to be_a(String)
        .and start_with("Zoho-oauthtoken")
    end

    it "caches the return value" do
      expect(connection.http).to eql(connection.http)
    end
  end
end
