# frozen_string_literal: true

RSpec.describe ZohoCRM::FieldSet do
  describe "#[]" do
    pending "TODO: Write some tests"
  end

  describe "#fetch" do
    pending "TODO: Write some tests"
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
    pending "TODO: Write some tests"
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
    pending "TODO: Write some tests"
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
