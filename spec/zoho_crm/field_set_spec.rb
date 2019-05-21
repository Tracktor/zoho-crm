# frozen_string_literal: true

RSpec.describe ZohoCRM::FieldSet do
  describe ZohoCRM::FieldSet::FieldNotFoundError do
    describe "Attributes" do
      subject { described_class.new(:email, fields: []) }

      it { is_expected.to have_attr_reader(:field_name) }
      it { is_expected.to have_attr_reader(:fields) }
    end

    it "is a kind of KeyError" do
      expect(described_class.new(:email, fields: [])).to be_a(KeyError)
    end

    describe "#initialize" do
      it "requires a \"field_name\" as argument and a \"fields:\" keyword argument", aggregate_failures: true do
        expect { described_class.new }.to raise_error(ArgumentError, /wrong number of arguments/)
        expect { described_class.new(:email) }.to raise_error(ArgumentError, /missing keyword/)
        expect { described_class.new(:email, fields: []) }.to_not raise_error
      end

      it "sets the \"field_name\" and \"fields\" attributes", aggregate_failures: true do
        field_name = :email
        fields = %i[name]
        error = described_class.new(field_name, fields: fields)

        expect(error.field_name).to eq(field_name)
        expect(error.fields).to eq(fields)
      end

      it "builds a descriptive message" do
        field_name = :email
        error = described_class.new(field_name, fields: [])

        expect(error.message).to match(/Field not found: #{field_name}/)
      end
    end
  end

  describe "#[]" do
    it "requires a key as argument", aggregate_failures: true do
      field_set = described_class.new

      expect { field_set[] }.to raise_error(ArgumentError, /wrong number of arguments/)
      expect { field_set[:email] }.to_not raise_error
    end

    context "when the field is found" do
      subject(:field_set) { described_class.new }

      let(:field) { ZohoCRM::Fields::Field.new(:email) }

      before do
        field_set << field
      end

      it "returns the field", aggregate_failures: true do
        expect(field_set[:email]).to eq(field)
        expect(field_set["email"]).to eq(field)
        expect(field_set[field]).to eq(field)
      end
    end

    context "when the field is not found" do
      subject(:field_set) { described_class.new }

      it "returns nil" do
        expect(field_set[:email]).to be_nil
      end
    end
  end

  describe "#fetch" do
    it "requires a key as argument", aggregate_failures: true do
      field_set = described_class.new
      field_set << ZohoCRM::Fields::Field.new(:email)

      expect { field_set.fetch }.to raise_error(ArgumentError, /wrong number of arguments/)
      expect { field_set.fetch(:email) }.to_not raise_error
    end

    it "accepts a default value as second argument" do
      field_set = described_class.new
      field = ZohoCRM::Fields::Field.new(:email)

      expect(field_set.fetch(:email, field)).to eq(field)
    end

    it "accepts a block to evaluate the default value" do
      field_set = described_class.new
      field = ZohoCRM::Fields::Field.new(:email)

      expect(field_set.fetch(:email) { field }).to eq(field)
    end

    it "raises an error if the key is nil", aggregate_failures: true do
      field_set = described_class.new

      expect { field_set.fetch(nil) }.to raise_error(ZohoCRM::FieldSet::FieldNotFoundError) do |error|
        expect(error.field_name).to eq(nil)
        expect(error.fields).to eq(field_set)
      end
    end

    it "raises an error if the key is empty", aggregate_failures: true do
      field_set = described_class.new

      expect { field_set.fetch("") }.to raise_error(ZohoCRM::FieldSet::FieldNotFoundError) do |error|
        expect(error.field_name).to eq("")
        expect(error.fields).to eq(field_set)
      end
    end

    context "when the field is found" do
      subject(:field_set) { described_class.new }

      let(:field) { ZohoCRM::Fields::Field.new(:email) }

      before do
        field_set << field
      end

      it "returns the field", aggregate_failures: true do
        expect(field_set.fetch(:email)).to eq(field)
        expect(field_set.fetch("email")).to eq(field)
        expect(field_set.fetch(field)).to eq(field)
      end
    end

    context "when the field is not found" do
      it "raises an error if the field is not found", aggregate_failures: true do
        field_set = described_class.new

        expect { field_set.fetch(:email) }.to raise_error(ZohoCRM::FieldSet::FieldNotFoundError) do |error|
          expect(error.field_name).to eq(:email)
          expect(error.fields).to eq(field_set)
        end
      end
    end
  end

  describe "#add" do
    subject(:field_set) { described_class.new }

    it "requires a field as argument", aggregate_failures: true do
      expect { field_set.add }.to raise_error(ArgumentError, /wrong number of arguments/)
      expect { field_set.add(42) }.to raise_error(TypeError)
      expect { field_set.add(ZohoCRM::Fields::Field.new(:email)) }.to_not raise_error
      expect { field_set.add(ZohoCRM::Fields::Enum.new(:status, %i[enabled])) }.to_not raise_error
    end

    it "adds the given field to the field_set" do
      expect { field_set.add(ZohoCRM::Fields::Field.new(:email)) }.to change(field_set, :size).by(1)
    end

    it "does not add duplicate fields to the field_set" do
      field_set.add(ZohoCRM::Fields::Field.new(:email))

      expect { field_set.add(ZohoCRM::Fields::Field.new(:email)) }.to_not change(field_set, :size)
    end

    it "returns the field_set" do
      expect(field_set.add(ZohoCRM::Fields::Field.new(:email))).to eql(field_set)
    end

    it "is chainable" do
      expect { field_set.add(ZohoCRM::Fields::Field.new(:email)).add(ZohoCRM::Fields::Field.new(:name)) }
        .to change(field_set, :size).by(2)
    end
  end

  describe "#<<" do
    subject(:field_set) { described_class.new }

    it "is an alias for #add" do
      expect(field_set.method(:<<)).to eql(field_set.method(:add))
    end

    it "requires a field as argument", aggregate_failures: true do
      expect { field_set.public_send(:<<) }.to raise_error(ArgumentError, /wrong number of arguments/)
      expect { field_set << 42 }.to raise_error(TypeError)
      expect { field_set << ZohoCRM::Fields::Field.new(:email) }.to_not raise_error
      expect { field_set << ZohoCRM::Fields::Enum.new(:status, %i[enabled]) }.to_not raise_error
    end

    it "adds the given field to the field_set" do
      expect { field_set << ZohoCRM::Fields::Field.new(:email) }.to change(field_set, :size).by(1)
    end

    it "does not add duplicate fields to the field_set" do
      field_set << ZohoCRM::Fields::Field.new(:email)

      expect { field_set << ZohoCRM::Fields::Field.new(:email) }.to_not change(field_set, :size)
    end

    it "is chainable" do
      expect { field_set << ZohoCRM::Fields::Field.new(:email) << ZohoCRM::Fields::Field.new(:name) }
        .to change(field_set, :size).by(2)
    end
  end

  describe "#include?" do
    it "requires a key as argument", aggregate_failures: true do
      field_set = described_class.new

      expect { field_set.include? }.to raise_error(ArgumentError, /wrong number of arguments/)
      expect { field_set.include?(:email) }.to_not raise_error
    end

    context "when the field is found" do
      subject(:field_set) { described_class.new }

      let(:field) { ZohoCRM::Fields::Field.new(:email) }

      before do
        field_set << field
      end

      it "returns true", aggregate_failures: true do
        expect(field_set.include?(:email)).to be(true)
        expect(field_set.include?("email")).to be(true)
        expect(field_set.include?(field)).to be(true)
      end
    end

    context "when the field is not found" do
      it "returns false" do
        field_set = described_class.new

        expect(field_set.include?(:email)).to be(false)
      end
    end
  end

  describe "#member?" do
    subject(:field_set) { described_class.new }

    it "is an alias for #size" do
      expect(field_set.method(:member?)).to eql(field_set.method(:include?))
    end
  end

  describe "#each" do
    pending "TODO: Write some tests"
  end

  describe "#size" do
    subject(:field_set) { described_class.new }

    it "returns the number of fields in the field_set", aggregate_failures: true do
      expect(field_set.size).to eq(0)

      field_set << ZohoCRM::Fields::Field.new(:name)

      expect(field_set.size).to eq(1)

      field_set << ZohoCRM::Fields::Field.new(:email)
      field_set << ZohoCRM::Fields::Field.new(:address)

      expect(field_set.size).to eq(3)

      field_set.delete(:name)

      expect(field_set.size).to eq(2)
    end
  end

  describe "#length" do
    subject(:field_set) { described_class.new }

    it "is an alias for #size" do
      expect(field_set.method(:length)).to eql(field_set.method(:size))
    end
  end

  describe "#empty?" do
    context "when the field_set contains fields" do
      subject(:field_set) do
        described_class.new.tap do |fs|
          fs << ZohoCRM::Fields::Field.new(:name)
        end
      end

      it "returns false" do
        expect(field_set.empty?).to be(false)
      end
    end

    context "when the field_set contains no fields" do
      subject(:field_set) { described_class.new }

      it "returns true" do
        expect(field_set.empty?).to be(true)
      end
    end
  end

  describe "#clear" do
    subject(:field_set) do
      described_class.new.tap do |fs|
        fs << ZohoCRM::Fields::Field.new(:name)
        fs << ZohoCRM::Fields::Field.new(:address)
      end
    end

    it "removes all fields from the field_set" do
      expect { field_set.clear }.to change(field_set, :size).from(2).to(0)
    end

    it "returns the field_set" do
      expect(field_set.clear).to equal(field_set)
    end
  end

  describe "#to_a" do
    let(:fields) do
      [
        ZohoCRM::Fields::Field.new(:name),
        ZohoCRM::Fields::Field.new(:email),
        ZohoCRM::Fields::Field.new(:address),
      ]
    end

    let(:field_set) do
      described_class.new.tap do |fs|
        fields.each { |f| fs << f }
        fs << fields.first
      end
    end

    it "returns the an Array of fields" do
      expect(field_set.to_a).to eq(fields)
    end
  end

  describe "#to_h" do
    let(:fields) do
      {
        "name" => ZohoCRM::Fields::Field.new(:name),
        "email" => ZohoCRM::Fields::Field.new(:email),
        "address" => ZohoCRM::Fields::Field.new(:address),
      }
    end

    let(:field_set) do
      described_class.new.tap do |fs|
        fields.each_value { |f| fs << f }
        fs << fields["name"]
      end
    end

    it "returns the a Hash with field names as keys and fields as values" do
      expect(field_set.to_h).to eq(fields)
    end
  end

  describe "#delete" do
    it "requires a key as argument", aggregate_failures: true do
      field_set = described_class.new

      expect { field_set.delete }.to raise_error(ArgumentError, /wrong number of arguments/)
      expect { field_set.delete(:email) }.to_not raise_error
    end

    it "returns the field set" do
      field_set = described_class.new

      expect(field_set.delete(:email)).to equal(field_set)
    end

    context "when the field is found" do
      subject(:field_set) { described_class.new }

      let(:field) { ZohoCRM::Fields::Field.new(:email) }

      before do
        field_set << field
      end

      it "removes the field from the field set", aggregate_failures: true do
        expect { field_set.delete(:email) }.to change(field_set, :size).by(-1)

        expect(field_set.include?(:email)).to be(false)
      end
    end

    context "when the field is not found" do
      subject(:field_set) { described_class.new }

      let(:field) { ZohoCRM::Fields::Field.new(:email) }

      before do
        field_set << field
      end

      it "doesn't remove any fields" do
        expect { field_set.delete(:name) }.to_not change(field_set, :size)
      end
    end
  end

  describe "#delete_if" do
    pending "TODO: Write some tests"
  end

  describe "#keep_if" do
    pending "TODO: Write some tests"
  end

  describe "#hash" do
    let(:fields) do
      {
        "name" => ZohoCRM::Fields::Field.new(:name),
        "email" => ZohoCRM::Fields::Field.new(:email),
        "address" => ZohoCRM::Fields::Field.new(:address),
      }
    end

    let(:field_set) do
      described_class.new.tap do |fs|
        fields.each_value { |f| fs << f }
        fs << fields["name"]
      end
    end

    it "computes a hash-code for the field_set" do
      expect(field_set.hash).to eq(fields.hash)
    end
  end

  describe "#eql?" do
    context "when the other value is a #{described_class.name}" do
      context "when the two field_sets are the same object" do
        let(:field_set) do
          described_class.new.tap do |fs|
            fs << ZohoCRM::Fields::Field.new(:name)
          end
        end

        it "returns true" do
          expect(field_set.eql?(field_set)).to be(true)
        end
      end

      context "when the two values contain the same set of fields" do
        let(:field_set) do
          described_class.new.tap do |fs|
            fs << ZohoCRM::Fields::Field.new(:name)
          end
        end

        let(:other_field_set) do
          described_class.new.tap do |fs|
            fs << ZohoCRM::Fields::Field.new(:name)
          end
        end

        it "returns true" do
          expect(field_set.eql?(other_field_set)).to be(true)
        end
      end

      context "when the two values contain the a different set of fields" do
        let(:field_set) do
          described_class.new.tap do |fs|
            fs << ZohoCRM::Fields::Field.new(:name)
          end
        end

        let(:other_field_set) do
          described_class.new.tap do |fs|
            fs << ZohoCRM::Fields::Field.new(:email)
          end
        end

        it "returns false" do
          expect(field_set.eql?(other_field_set)).to be(false)
        end
      end
    end

    context "when the other value is not a #{described_class.name}" do
      it "returns false" do
        expect(described_class.new.eql?([])).to be(false)
      end
    end
  end

  describe "#==" do
    pending "TODO: Write some tests"
  end

  describe "#freeze" do
    subject(:field_set) do
      described_class.new.tap do |fs|
        fs << ZohoCRM::Fields::Field.new(:name)
      end
    end

    it "freezes the field_set", aggregate_failures: true do
      expect(field_set.size).to eq(1)

      expect { field_set.freeze }
        .to change(field_set, :frozen?).from(false).to(true)

      expect { field_set.add(ZohoCRM::Fields::Field.new(:email)) }
        .to raise_error(FrozenError)

      expect(field_set.size).to eq(1)
    end
  end

  describe "#taint" do
    subject(:field_set) do
      described_class.new.tap do |fs|
        fs << ZohoCRM::Fields::Field.new(:name)
      end
    end

    it "taints the field_set" do
      expect { field_set.taint }
        .to change(field_set, :tainted?).from(false).to(true)
    end
  end

  describe "#untaint" do
    subject(:field_set) do
      described_class.new.tap do |fs|
        fs << ZohoCRM::Fields::Field.new(:name)
      end
    end

    before do
      field_set.taint
    end

    it "taints the field_set" do
      expect { field_set.untaint }
        .to change(field_set, :tainted?).from(true).to(false)
    end
  end

  describe "#inspect" do
    subject(:field_set) do
      described_class.new.tap do |fs|
        fs << ZohoCRM::Fields::Field.new(:name)
        fs << ZohoCRM::Fields::Field.new(:email)
      end
    end

    it "returns a human-readable representation of the field_set" do
      expect(field_set.inspect).to match(/\A#<#{described_class.name} \(name: .+ email: .+\)>\z/)
    end
  end
end
