# frozen_string_literal: true

RSpec.describe ZohoCRM::Fields::Enum do
  describe ZohoCRM::Fields::Enum::InvalidValueError do
    pending "TODO: Write some tests"
  end

  it "is a kind of ZohoCRM::Field" do
    expect(described_class.new(:status, %i[enabled])).to be_a(ZohoCRM::Fields::Field)
  end

  describe "Attributes" do
    subject { described_class.new(:status, %i[enabled]) }

    it { is_expected.to have_attr_reader(:elements) }
  end

  describe ".build" do
    it "requires a field_name as argument and values in the options", aggregate_failures: true do
      expect { described_class.build }.to raise_error(ArgumentError, /wrong number of arguments/)
      expect { described_class.build(:status) }.to raise_error(ArgumentError, /'values' key not found in options/)
      expect { described_class.build(:status, values: []) }.to_not raise_error
    end

    context "with a :values key in the options" do
      subject(:field) { described_class.build(:status, values: %i[enabled disabled]) }

      it "builds a field of type #{described_class.name}" do
        expect(field).to be_an_instance_of(described_class)
      end
    end

    context "without a :values key in the options" do
      it "raises an error" do
        expect { described_class.build(:status, label: "Status") }
          .to raise_error(ArgumentError, %('values' key not found in options: {"label"=>"Status"}))
      end
    end
  end

  describe "#initialize" do
    it "normalizes the options", aggregate_failures: true do
      field = described_class.new(:status, [], foo: 42)

      expect(field.options.key?(:foo)).to be(false)
      expect(field.options.key?("foo")).to be(true)
    end

    it 'requires a "field_name" and a list of "elements"', aggregate_failures: true do
      expect { described_class.new }.to raise_error(ArgumentError, /wrong number of arguments/)
      expect { described_class.new(:status) }.to raise_error(ArgumentError, /wrong number of arguments/)
      expect { described_class.new(:status, []) }.to_not raise_error
    end

    context 'when the "elements" argument is an Array' do
      it "normalizes the elements" do
        elements = %i[enabled disabled]
        field = described_class.new(:status, elements)

        expect(field.elements).to eq({"enabled" => :enabled, "disabled" => :disabled})
      end
    end

    context 'when the "elements" argument is a Hash' do
      it "sets the #elements attribute" do
        elements = {enabled: 1, disabled: 2}
        field = described_class.new(:status, elements)

        expect(field.elements).to eq({enabled: 1, disabled: 2})
      end
    end
  end

  describe "#value_for" do
    pending "TODO: Write some tests"
  end

  describe "#enum?" do
    subject(:field) { described_class.new(:status, %i[enabled]) }

    it "returns true" do
      expect(field).to be_enum
    end
  end

  describe "#human_readable_elements" do
    pending "TODO: Write some tests"
  end

  describe "#inspect" do
    pending "TODO: Write some tests"
  end
end
