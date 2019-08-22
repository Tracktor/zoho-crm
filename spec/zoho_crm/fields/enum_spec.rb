# frozen_string_literal: true

RSpec.describe ZohoCRM::Fields::Enum do
  describe ZohoCRM::Fields::Enum::InvalidValueError do
    describe "Attributes" do
      let(:enum) { ZohoCRM::Fields::Enum.new(:status, %i[enabled]) }
      let(:error) { described_class.new(enum: enum, value: nil) }

      it { expect(error).to have_attr_reader(:enum) }
      it { expect(error).to have_attr_reader(:value) }
    end

    it "is a kind of KeyError" do
      enum = ZohoCRM::Fields::Enum.new(:status, %i[enabled])

      expect(described_class.new(enum: enum, value: nil)).to be_a(KeyError)
    end

    describe "#initialize" do
      let(:enum) { ZohoCRM::Fields::Enum.new(:status, %i[enabled]) }

      it "requires \"enum:\" and \"value:\" keyword arguments", aggregate_failures: true do
        expect { described_class.new }.to raise_error(ArgumentError, /missing keyword/)
        expect { described_class.new(enum: enum) }.to raise_error(ArgumentError, /missing keyword/)
        expect { described_class.new(value: nil) }.to raise_error(ArgumentError, /missing keyword/)
        expect { described_class.new(enum: enum, value: nil) }.to_not raise_error
      end

      it "sets the \"enum\" and \"value\" attributes", aggregate_failures: true do
        value = :disabled
        error = described_class.new(enum: enum, value: value)

        expect(error.enum).to eq(enum)
        expect(error.value).to eq(value)
      end

      it "builds a descriptive message" do
        value = :disabled
        error = described_class.new(enum: enum, value: value)

        expect(error.message).to match(/Invalid value #{Regexp.escape(value.inspect)} for enum: #{Regexp.escape(enum.human_readable_elements)}/)
      end
    end
  end

  it "is a kind of ZohoCRM::Field" do
    expect(described_class.new(:status, %i[enabled])).to be_a(ZohoCRM::Fields::Field)
  end

  describe "Attributes" do
    subject { described_class.new(:status, %i[enabled]) }

    it { is_expected.to have_attr_reader(:elements) }
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
      it "converts all keys to strings" do
        field = described_class.new(:status, {enabled: 1, disabled: 2})

        expect(field.elements.keys.all? { |k| String === k }).to be(true)
      end

      it "sets the #elements attribute" do
        elements = {enabled: 1, disabled: 2}
        field = described_class.new(:status, elements)

        expect(field.elements).to eq({"enabled" => 1, "disabled" => 2})
      end
    end
  end

  describe "#value=" do
    context "when the given value is in the #elements attribute" do
      it "does not raise an error", aggregate_failures: true do
        field = described_class.new(:status, {active: 1, inactive: 2})

        expect { field.value = :active }.to_not raise_error
        expect { field.value = 1 }.to_not raise_error
        expect { field.value = "inactive" }.to_not raise_error
        expect { field.value = 2 }.to_not raise_error
      end

      it "sets the static value" do
        field = described_class.new(:status, {active: 1, inactive: 2})
        static_value = :active

        expect { field.value = static_value }
          .to change { field.send(:static_value) }
          .to(static_value)
      end
    end

    context "when the given value is nil" do
      it "does not raise an error" do
        field = described_class.new(:status, %i[active inactive])

        expect { field.value = nil }.to_not raise_error
      end

      it "removes the static value" do
        field = described_class.new(:status, %i[active inactive])
        field.value = :active

        expect { field.value = nil }
          .to change { field.send(:static_value) }
          .from(:active)
          .to(nil)
      end
    end

    context "when the given value is not in the #elements attribute" do
      it "raises an error" do
        field = described_class.new(:status, %i[active inactive])

        expect { field.value = :deleted }
          .to raise_error(described_class::InvalidValueError,
                          /Invalid value :deleted for enum: #{Regexp.escape(field.human_readable_elements)}/)
      end

      it "doesn't set the static value" do
        field = described_class.new(:status, %i[active inactive])

        expect {
          begin
            field.value = :deleted
          rescue described_class::InvalidValueError
          end
        }.to_not change { field.send(:static_value) }
      end
    end
  end

  describe "#value_for" do
    context "when the field has a static value" do
      subject(:field) do
      end

      before do
        MyUser = Struct.new(:status)
      end

      after do
        Object.send(:remove_const, :MyUser)
      end

      it "returns the raw value", aggregate_failures: true do
        field = described_class.new(:status, {active: 1, inactive: 2})
        user = MyUser.new(:active)

        field.value = :inactive
        expect(field.value_for(user)).to eq(2)

        field.value = 1
        expect(field.value_for(user)).to eq(1)
      end
    end

    context "when the field doesn't have a static value" do
      context "when the computed value is in the #elements attribute" do
        subject(:field) do
          described_class.new(:status, {active: 1, inactive: 2}).tap do |f|
            f.value = nil
          end
        end

        before do
          MyUser = Struct.new(:status)
        end

        after do
          Object.send(:remove_const, :MyUser)
        end

        it "does not raise an error", aggregate_failures: true do
          expect { field.value_for(MyUser.new(:active)) }.to_not raise_error
          expect { field.value_for(MyUser.new(1)) }.to_not raise_error
          expect { field.value_for(MyUser.new("inactive")) }.to_not raise_error
          expect { field.value_for(MyUser.new(2)) }.to_not raise_error
        end

        it "returns the raw value", aggregate_failures: true do
          expect(field.value_for(MyUser.new(:active))).to eq(1)
          expect(field.value_for(MyUser.new(1))).to eq(1)
          expect(field.value_for(MyUser.new("inactive"))).to eq(2)
          expect(field.value_for(MyUser.new(2))).to eq(2)
        end
      end

      context "when the computed value is not in the #elements attribute" do
        subject(:field) do
          described_class.new(:status, %i[active inactive]).tap do |f|
            f.value = nil
          end
        end

        before do
          MyUser = Struct.new(:status)
        end

        after do
          Object.send(:remove_const, :MyUser)
        end

        it "raises an error", aggregate_failures: true do
          expect { field.value_for(MyUser.new(:deleted)) }
            .to raise_error(described_class::InvalidValueError,
              /Invalid value :deleted for enum: #{Regexp.escape(field.human_readable_elements)}/)

          expect { field.value_for(MyUser.new("archived")) }
            .to raise_error(described_class::InvalidValueError,
              /Invalid value "archived" for enum: #{Regexp.escape(field.human_readable_elements)}/)
        end
      end
    end
  end

  describe "#enum?" do
    subject(:field) { described_class.new(:status, %i[enabled]) }

    it "returns true" do
      expect(field).to be_enum
    end
  end

  describe "#element?" do
    subject(:field) { described_class.new(:status, {"enabled" => 1, "disabled" => 2}) }

    context "when the value is a key in the #elements attribute" do
      it "returns true" do
        expect(field.element?("enabled")).to be(true)
      end

      it "converts the value to a String before the lookup" do
        expect(field.element?(:enabled)).to be(true)
      end
    end

    context "when the value is a raw value in the #elements attribute" do
      it "returns true" do
        expect(field.element?(2)).to be(true)
      end
    end

    context "when the value is not in the #elements attribute" do
      it "returns false" do
        expect(field.element?(:invalid)).to be(false)
      end
    end
  end

  describe "#element" do
    subject(:field) { described_class.new(:status, {"enabled" => 1, "disabled" => 2}) }

    context "when the value is a key in the #elements attribute" do
      it "returns the raw value" do
        expect(field.element("enabled")).to eq(1)
      end

      it "converts the value to a String before the lookup" do
        expect(field.element(:disabled)).to eq(2)
      end
    end

    context "when the value is a raw value in the #elements attribute" do
      it "returns the value itself" do
        expect(field.element(1)).to eq(1)
      end
    end

    context "when the value is not in the #elements attribute" do
      it "returns nil" do
        expect(field.element(:invalid)).to be_nil
      end
    end
  end

  describe "#human_readable_elements" do
    subject(:field) { described_class.new(:status, %i[enabled disabled]) }

    it "returns a human-readable representation of the elements" do
      expect(field.human_readable_elements).to match(/\A\["enabled" \(:enabled\), "disabled" \(:disabled\)\]\z/)
    end
  end

  describe "#inspect" do
    subject(:field) { described_class.new(:status, %i[enabled]) }

    it "returns a human-readable representation of the enum" do
      regex =
        /
          \A\#<#{described_class.name}
          \ name:\ "status"
          \ api_name:\ "Status"
          \ field_method:\ "status"
          \ elements:\ #{Regexp.escape(field.human_readable_elements)}
          \ options:\ \{\}>\z
        /x

      expect(field.inspect).to match(regex)
    end
  end
end
