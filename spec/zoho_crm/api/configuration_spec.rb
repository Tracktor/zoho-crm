# frozen_string_literal: true

RSpec.describe ZohoCRM::API do
  describe ".configure" do
    it "yields a block with a config instance as argument", aggregate_failures: true do
      expect { |b| described_class.configure(&b) }.to yield_with_args(described_class.config)

      described_class.configure do |config|
        expect(config).to be_an_instance_of(ZohoCRM::API::Configuration)
      end
    end

    context "when an env name is passed as an argument" do
      it "yields a block with the config associated with the env", aggregate_failures: true do
        expect { |b| described_class.configure(:beta, &b) }.to yield_with_args(described_class.config(:beta))

        described_class.configure(:beta) do |config|
          expect(config.environment).to eq(:beta)
        end
      end
    end

    context "when called with no argument" do
      it "yields a block with the default config", aggregate_failures: true do
        expect { |b| described_class.configure(&b) }.to yield_with_args(described_class.config(:default))

        described_class.configure do |config|
          expect(config.environment).to eq(:default)
        end
      end
    end
  end

  describe ".config" do
    it "returns an instance of ZohoCRM::API::Configuration" do
      expect(described_class.config).to be_an_instance_of(ZohoCRM::API::Configuration)
    end

    it "caches the return value" do
      expect(described_class.config).to eql(described_class.config)
    end

    it "can have multiple configurations" do
      expect(described_class.config(:stable)).to_not eq(described_class.config(:beta))
    end

    context "when an env name is passed as an argument" do
      it "returns the config associated with the env" do
        expect(described_class.config(:beta)).to eql(described_class.config(:beta))
      end
    end

    context "when called with no argument" do
      it "returns the default config" do
        expect(described_class.config).to eql(described_class.config(:default))
      end
    end
  end

  describe ".configs" do
    before do
      described_class.configure(:legacy) {}
      described_class.configure(:beta) {}
    end

    it "returns a Hash of registered Zoho CRM configurations", aggregate_failures: true do
      expect(described_class.configs).to be_an_instance_of(Hash)
      expect(described_class.configs).to include({
        legacy: an_instance_of(ZohoCRM::API::Configuration),
        beta: an_instance_of(ZohoCRM::API::Configuration),
      })
    end
  end
end

RSpec.describe ZohoCRM::API::Configuration do
  describe "Attributes" do
    it { is_expected.to have_attr_accessor(:region) }
    it { is_expected.to have_attr_accessor(:client_id) }
    it { is_expected.to have_attr_accessor(:client_secret) }
    it { is_expected.to have_attr_accessor(:scopes) }
    it { is_expected.to have_attr_accessor(:redirect_url) }
    it { is_expected.to have_attr_accessor(:logger) }
    it { is_expected.to have_attr_accessor(:sandbox) }
    it { is_expected.to have_attr_reader(:environment) }
    it { is_expected.to_not have_attr_writer(:environment) }
  end

  describe "#initialize" do
    it "sets default values for attributes" do
      configuration = described_class.new

      expect(configuration).to have_attributes({
        region: "com",
        scopes: [],
        timeout: 5,
        logger: an_instance_of(Logger),
        sandbox: false,
      })
    end

    it "accepts a configuration environment as argument" do
      configuration = described_class.new(:beta)

      expect(configuration.environment).to eq(:beta)
    end

    context "when no configuration environment is passed as argument" do
      it "uses the default configuration environment" do
        configuration = described_class.new

        expect(configuration.environment).to eq(:default)
      end
    end
  end

  describe "#region=" do
    context "when the given value is not a valid region" do
      it "raises an error", aggregate_failures: true do
        configuration = described_class.new
        error_message = "Invalid region: \"fr\". Acceptable values: com, eu, in"

        expect { configuration.region = "fr" }.to raise_error(ZohoCRM::API::ConfigurationError, error_message)
        expect { configuration.region = "eu" }.to_not raise_error
      end

      it "doesn't set the `region' attribute" do
        configuration = described_class.new

        expect {
          begin
            configuration.region = "fr"
          rescue ZohoCRM::API::ConfigurationError
          end
        }.to_not change(configuration, :region)
      end
    end

    context "when the given value is a valid region" do
      it "set the `region' attribute" do
        configuration = described_class.new

        expect { configuration.region = "eu" }.to change { configuration.region }.to("eu")
      end

      it "converts the given value to a String" do
        configuration = described_class.new
        configuration.region = :eu

        expect(configuration.region).to eq("eu")
      end
    end
  end

  describe "#scopes=" do
    it "set the `scopes' attribute" do
      configuration = described_class.new
      scopes = %w[ZohoCRM.modules.all]

      expect { configuration.scopes = scopes }.to change { configuration.scopes }.to(scopes)
    end

    it "converts the given value to an Array" do
      configuration = described_class.new
      scopes = "ZohoCRM.modules.all"

      expect { configuration.scopes = scopes }.to change { configuration.scopes }.to([scopes])
    end
  end

  describe "#base_url" do
    context "when the sandbox config is set to \"false\"" do
      it "returns the Zoho CRM API URL" do
        configuration = described_class.new
        configuration.sandbox = false

        expect(configuration.base_url).to eq("https://www.zohoapis.com/crm/v2")
      end

      it "returns the Zoho CRM API URL with the correct region" do
        configuration = described_class.new
        configuration.sandbox = false
        configuration.region = "eu"

        expect(configuration.base_url).to eq("https://www.zohoapis.eu/crm/v2")
      end
    end

    context "when the sandbox config is set to \"true\"" do
      it "returns the Zoho CRM API URL" do
        configuration = described_class.new
        configuration.sandbox = true

        expect(configuration.base_url).to eq("https://sandbox.zohoapis.com/crm/v2")
      end

      it "returns the Zoho CRM API URL with the correct region" do
        configuration = described_class.new
        configuration.sandbox = true
        configuration.region = "eu"

        expect(configuration.base_url).to eq("https://sandbox.zohoapis.eu/crm/v2")
      end
    end
  end

  describe "#accounts_url" do
    it "returns the Zoho accounts URL" do
      configuration = described_class.new

      expect(configuration.accounts_url).to eq("https://accounts.zoho.com")
    end

    it "returns the Zoho accounts URL with the correct region" do
      configuration = described_class.new
      configuration.region = "eu"

      expect(configuration.accounts_url).to eq("https://accounts.zoho.eu")
    end
  end

  describe "#developer_console_url" do
    it "returns the Zoho developer console URL" do
      configuration = described_class.new

      expect(configuration.developer_console_url).to eq("https://accounts.zoho.com/developerconsole")
    end

    it "returns the Zoho developer console URL with the correct region" do
      configuration = described_class.new
      configuration.region = "eu"

      expect(configuration.developer_console_url).to eq("https://accounts.zoho.eu/developerconsole")
    end
  end
end
