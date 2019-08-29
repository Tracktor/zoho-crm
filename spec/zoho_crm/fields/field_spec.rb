# frozen_string_literal: true

RSpec.describe ZohoCRM::Fields::Field do
  describe ZohoCRM::Fields::Field::UnsupportedMethodTypeError do
    it "requires an object", aggregate_failures: true do
      expect { described_class.new }.to raise_error(ArgumentError, /wrong number of arguments/)
      expect { described_class.new(nil) }.to_not raise_error
    end

    it "is a kind of TypeError" do
      expect(described_class.new(nil)).to be_kind_of(TypeError)
    end

    # Note: this is a terrible description...
    it "has a descriptive message" do
      object = 42
      error = described_class.new(object)

      expect(error.message).to match(/expected to receive one of \[.+\] but received a #{object.class.name}: #{object.inspect}/)
    end
  end

  describe "Attributes" do
    subject { described_class.new(:email) }

    it { is_expected.to have_attr_reader(:name) }
    it { is_expected.to have_attr_reader(:api_name) }
    it { is_expected.to have_attr_reader(:label) }
    it { is_expected.to have_attr_reader(:field_method) }
    it { is_expected.to have_attr_reader(:options) }
  end

  describe "#initialize" do
    it "normalizes the options", aggregate_failures: true do
      field = described_class.new(:email, foo: 42)

      expect(field.options.key?(:foo)).to be(false)
      expect(field.options.key?("foo")).to be(true)
    end

    it 'requires a "field_name"', aggregate_failures: true do
      expect { described_class.new }.to raise_error(ArgumentError, /wrong number of arguments/)
      expect { described_class.new(:email) }.to_not raise_error
    end

    context 'when the "field_name" is blank' do
      it "raises an error", aggregate_failures: true do
        expect { described_class.new(false) }.to raise_error(ArgumentError, "name can't be blank")
        expect { described_class.new(nil) }.to raise_error(ArgumentError, "name can't be blank")
        expect { described_class.new("") }.to raise_error(ArgumentError, "name can't be blank")
        expect { described_class.new(" ") }.to raise_error(ArgumentError, "name can't be blank")
      end
    end

    context "with options" do
      subject(:field) { described_class.new(:full_name, :name, as: "Full_Name", label: "Full Name (First Name + Last Name)") }

      it "sets the field's attributes" do
        expect(field).to have_attributes({
          name: "full_name",
          api_name: "Full_Name",
          field_method: :name,
          label: "Full Name (First Name + Last Name)",
          options: {},
        })
      end

      it 'deletes the "api_name" and "label" keys', aggregate_failures: true do
        expect(field.options.key?("api_name")).to be(false)
        expect(field.options.key?("label")).to be(false)
      end
    end

    context "without options" do
      subject(:field) { described_class.new(:first_name) }

      it "sets field's #name" do
        expect(field.name).to eq("first_name")
      end

      it "infers the #api_name from the field's #name" do
        expect(field.api_name).to eq("First_Name")
      end

      it "sets the #field_method to the field's #name" do
        expect(field.field_method).to eq("first_name")
      end

      it "infers the #label from the field's #api_name" do
        expect(field.label).to eq("First Name")
      end
    end

    context "when used with a block" do
      it "uses the block as the #field_method" do
        field_method = proc { 10 }
        field = described_class.new(:age, &field_method)

        expect(field.field_method).to eq(field_method)
      end

      it 'takes precedence over the "field_method" argument' do
        field_method = proc { "Sabine Jelahaie" }
        field = described_class.new(:name, :full_name, &field_method)

        expect(field.field_method).to eq(field_method)
      end
    end

    context "when the #field_method is of an unsupported type" do
      it "raises an error" do
        field_method = true

        expect { described_class.new(:enabled, field_method) }
          .to raise_error(described_class::UnsupportedMethodTypeError, /expected to receive .+ but received a #{field_method.class.name}: #{field_method.inspect}/)
      end
    end
  end

  describe "#clone" do
    before do
      MyUser = Struct.new(:first_name, :last_name, keyword_init: true)
    end

    after do
      Object.send(:remove_const, :MyUser)
    end

    it "clones the field" do
      original_field = described_class.new(:first_name)
      cloned_field = original_field.clone

      expect(cloned_field.object_id).to_not eq(original_field.object_id)
    end

    it "clones the field's attributes", aggregate_failures: true do
      object = MyUser.new(first_name: "Sabine", last_name: "Jelahaie")
      original_field = described_class.new(:full_name, as: "Full_Name", label: "Full Name (First Name + Last Name)") { |object|
        "#{object.first_name} #{object.last_name}"
      }
      cloned_field = original_field.clone

      expect(cloned_field.name).to eq(original_field.name)
      expect(cloned_field.api_name).to eq(original_field.api_name)
      expect(cloned_field.label).to eq(original_field.label)

      expect(cloned_field.options.object_id).to_not eq(original_field.options.object_id)
      expect(cloned_field.field_method.object_id).to_not eq(original_field.field_method.object_id)

      expect(cloned_field.value_for(object)).to eq(original_field.value_for(object))
    end

    it "clones the static value of the cloned field", aggregate_failures: true do
      original_field = described_class.new(:first_name)
      original_field.value = "Sabine"
      cloned_field = original_field.clone

      expect(original_field).to be_static
      expect(cloned_field).to be_static

      expect(cloned_field.send(:static_value).object_id).to_not eq(original_field.send(:static_value).object_id)

      expect(original_field.send(:static_value)).to eq("Sabine")
      expect(cloned_field.send(:static_value)).to eq("Sabine")

      # The `instance_variable_get` method will raise a NameError if the instance variable
      # doesn't exist. This expectation makes sure that the `@static_value` instance
      # variable is `nil` regardless of the implementation of the `static_value` method.
      expect(original_field.instance_variable_get(:@static_value)).to eq("Sabine")
      expect(cloned_field.instance_variable_get(:@static_value)).to eq("Sabine")
    end
  end

  describe "#dup" do
    before do
      MyUser = Struct.new(:first_name, :last_name, keyword_init: true)
    end

    after do
      Object.send(:remove_const, :MyUser)
    end

    it "duplicates the field" do
      original_field = described_class.new(:first_name)
      dupped_field = original_field.dup

      expect(dupped_field.object_id).to_not eq(original_field.object_id)
    end

    it "duplicates the field's attributes", aggregate_failures: true do
      object = MyUser.new(first_name: "Sabine", last_name: "Jelahaie")
      original_field = described_class.new(:full_name, as: "Full_Name", label: "Full Name (First Name + Last Name)") { |object|
        "#{object.first_name} #{object.last_name}"
      }
      dupped_field = original_field.dup

      expect(dupped_field.name).to eq(original_field.name)
      expect(dupped_field.api_name).to eq(original_field.api_name)
      expect(dupped_field.label).to eq(original_field.label)

      expect(dupped_field.options.object_id).to_not eq(original_field.options.object_id)
      expect(dupped_field.field_method.object_id).to_not eq(original_field.field_method.object_id)

      expect(dupped_field.value_for(object)).to eq(original_field.value_for(object))
    end

    it "removes the static value of the dupped field", aggregate_failures: true do
      original_field = described_class.new(:first_name)
      original_field.value = "Sabine"
      dupped_field = original_field.dup

      expect(original_field).to be_static
      expect(dupped_field).to_not be_static

      expect(original_field.send(:static_value)).to eq("Sabine")
      expect(dupped_field.send(:static_value)).to be_nil

      # The `instance_variable_get` method will raise a NameError if the instance variable
      # doesn't exist. This expectation makes sure that the `@static_value` instance
      # variable is `nil` regardless of the implementation of the `static_value` method.
      expect(original_field.instance_variable_get(:@static_value)).to eq("Sabine")
      expect(dupped_field.instance_variable_get(:@static_value)).to be_nil
    end
  end

  describe "#api_name=" do
    context "when a blank value is assigned" do
      subject(:field) { described_class.new(:name) }

      it "uses the inferred api_name", aggregate_failures: true do
        field.api_name = nil

        expect(field.api_name).to eq("Name")
        expect { field.api_name = false }.to_not change(field, :api_name)
        expect { field.api_name = "" }.to_not change(field, :api_name)
        expect { field.api_name = " " }.to_not change(field, :api_name)
      end
    end

    context "when a non-blank value is assigned" do
      subject(:field) { described_class.new(:name) }

      it "sets the #api_name to the given value" do
        field.api_name = "Full_Name"

        expect(field.api_name).to eq("Full_Name")
      end

      it "converts the value to a String" do
        field.api_name = :Full_Name

        expect(field.api_name).to eq("Full_Name")
      end

      it "strips the the whitespace from the value before assigning it" do
        field.api_name = "   Full_Name   "

        expect(field.api_name).to eq("Full_Name")
      end
    end
  end

  describe "#label=" do
    context "when a blank value is assigned" do
      subject(:field) { described_class.new(:name) }

      it "is inferred from #api_name" do
        field.api_name = "Full_Name"
        field.label = nil

        expect(field.label).to eq("Full Name")
      end
    end

    context "when a non-blank value is assigned" do
      subject(:field) { described_class.new(:email) }

      it "sets the #api_name to the given value" do
        field.label = "Email Address"

        expect(field.label).to eq("Email Address")
      end

      it "strips the the whitespace from the value before assigning it" do
        field.label = "   Email Address   "

        expect(field.label).to eq("Email Address")
      end
    end
  end

  describe "#value=" do
    it "sets the static value" do
      field = described_class.new(:name)
      static_value = "John Smith"

      expect { field.value = static_value }
        .to change { field.send(:static_value) }
        .to(static_value)
    end
  end

  describe "#value_for" do
    context "when the field has a static value" do
      before do
        MyUser = Struct.new(:full_name)
      end

      after do
        Object.send(:remove_const, :MyUser)
      end

      it "returns the static value" do
        field = described_class.new(:name, :full_name)
        field.value = "John Doe"
        object = MyUser.new("Sabine Jelahaie")

        expect(field.value_for(object)).to eq("John Doe")
      end
    end

    context "when the field doesn't have a static value" do
      context "when the #field_method is a String" do
        before do
          MyUser = Struct.new(:full_name)
        end

        after do
          Object.send(:remove_const, :MyUser)
        end

        it "calls the method of the same name on the object" do
          field = described_class.new(:name, "full_name")
          field.value = nil
          object = MyUser.new("Sabine Jelahaie")

          expect(field.value_for(object)).to eq(object.full_name)
        end
      end

      context "when the #field_method is a Symbol" do
        before do
          MyUser = Struct.new(:full_name)
        end

        after do
          Object.send(:remove_const, :MyUser)
        end

        it "calls the method of the same name on the object" do
          field = described_class.new(:name, :full_name)
          field.value = nil
          object = MyUser.new("Sabine Jelahaie")

          expect(field.value_for(object)).to eq(object.full_name)
        end
      end

      context "when the #field_method is a Proc" do
        before do
          MyUser = Struct.new(:first_name, :last_name, keyword_init: true)
        end

        after do
          Object.send(:remove_const, :MyUser)
        end

        it "executes the Proc in the context of the object", aggregate_failures: true do
          field1 = described_class.new(:name) { |obj| "#{obj.last_name}, #{obj.first_name} #{obj.last_name}" }
          field2 = described_class.new(:name) { "#{first_name} ! #{first_name} ! #{first_name} #{last_name}" }
          field1.value = nil
          field2.value = nil
          object = MyUser.new(first_name: "Sabine", last_name: "Jelahaie")

          expect(field1.value_for(object)).to eq("#{object.last_name}, #{object.first_name} #{object.last_name}")
          expect(field2.value_for(object)).to eq("#{object.first_name} ! #{object.first_name} ! #{object.first_name} #{object.last_name}")
        end
      end
    end
  end

  describe "#static?" do
    context "when there is a static value" do
      it "returns true" do
        field = described_class.new(:name)
        field.value = "John Smith"

        expect(field).to be_static
      end
    end

    context "when the static value is nil" do
      it "returns false" do
        field = described_class.new(:name)
        field.value = nil

        expect(field).to_not be_static
      end
    end

    context "when there is no static value" do
      it "returns false" do
        field = described_class.new(:name)

        expect(field).to_not be_static
      end
    end
  end

  describe "#enum?" do
    subject(:field) { described_class.new(:email) }

    it "returns false" do
      expect(field).to_not be_enum
    end
  end

  describe "#hash" do
    subject(:field) { described_class.new(:email) }

    it "is the same as the hash of its :name attribute" do
      expect(field.hash).to eq(field.name.hash)
    end
  end

  describe "#eql?" do
    context "when the other value is a ZohoCRM::Fields::Field" do
      context "when the other field has the same name" do
        it "returns true" do
          field = described_class.new(:email)
          other_field = described_class.new(:email)

          expect(field.eql?(other_field)).to be(true)
        end
      end

      context "when the other field has a different name" do
        it "returns false" do
          field = described_class.new(:email)
          other_field = described_class.new(:name)

          expect(field.eql?(other_field)).to be(false)
        end
      end
    end

    context "when the other value is a Symbol" do
      context "when the symbol is the same as the field's name" do
        it "returns true" do
          field = described_class.new(:email)

          expect(field.eql?(:email)).to be(true)
        end
      end

      context "when the symbol is different than the field's name" do
        it "returns false" do
          field = described_class.new(:email)

          expect(field.eql?(:name)).to be(false)
        end
      end
    end

    context "when the other value is a String" do
      context "when the symbol is the same as the field's name" do
        it "returns true" do
          field = described_class.new(:email)

          expect(field.eql?("email")).to be(true)
        end
      end

      context "when the symbol is different than the field's name" do
        it "returns false" do
          field = described_class.new(:email)

          expect(field.eql?("name")).to be(false)
        end
      end
    end

    context "when the other value is of an unsupported type" do
      it "returns false" do
        field = described_class.new(:leet)

        expect(field.eql?(1337)).to be(false)
      end
    end
  end

  describe "#==" do
    subject(:field) { described_class.new(:alias) }

    it "is an alias for #eql?", aggregate_failures: true do
      expect(field.method(:==)).to eql(field.method(:eql?))
      expect(field.method(:==).original_name).to eq(:eql?)
    end
  end

  describe "#inspect" do
    subject(:field) { described_class.new(:email, :email_address, as: "Email") }

    it "returns a human-readable representation of the field" do
      regex =
        /
          \A\#<#{described_class.name}
          \ name:\ "email"
          \ api_name:\ "Email"
          \ field_method:\ :email_address
          \ options:\ \{\}>\z
        /x

      expect(field.inspect).to match(regex)
    end
  end
end
