# frozen_string_literal: true

RSpec.describe ZohoCRM::Model do
  describe "Attributes" do
    it "has :zoho_module_name class-level attribute reader" do
      model = Class.new(described_class)

      expect(model).to have_attr_reader(:zoho_module_name)
    end

    it "has a :object attribute reader" do
      model = Class.new(described_class)

      expect(model.new(double)).to have_attr_reader(:object)
    end
  end

  describe ".zoho_module" do
    it "requires an argument", aggregate_failures: true do
      model = Class.new(described_class)

      expect { model.zoho_module }.to raise_error(ArgumentError)
      expect { model.zoho_module("name") }.to_not raise_error
    end

    it "sets the module name" do
      model = Class.new(described_class) { zoho_module("my_module") }

      expect(model.zoho_module_name).to eq("my_module")
    end

    context "when the given name is nil" do
      it "sets the module name to nil" do
        model = Class.new(described_class) { zoho_module(nil) }

        expect(model.zoho_module_name).to be_nil
      end
    end

    context "when the given name is empty" do
      it "sets the module name to nil" do
        model = Class.new(described_class) { zoho_module("") }

        expect(model.zoho_module_name).to be_nil
      end
    end

    context "when the given name is a Symbol" do
      it "sets the module name to the String representation of the given name" do
        model = Class.new(described_class) { zoho_module(:my_module) }

        expect(model.zoho_module_name).to eq("my_module")
      end
    end
  end

  describe ".zoho_fields" do
    it "is a FieldSet" do
      model = Class.new(described_class)

      expect(model.zoho_fields).to be_a(ZohoCRM::FieldSet)
    end
  end

  describe ".zoho_field" do
    it "requires a name as argument", aggregate_failures: true do
      model = Class.new(described_class)

      expect { model.zoho_field }.to raise_error(ArgumentError)
      expect { model.zoho_field(:email) }.to_not raise_error
    end

    it "defines a method with the given name" do
      model = Class.new(described_class) { zoho_field(:first_name) }

      expect(model.method_defined?(:first_name)).to be(true)
    end

    it "adds a zoho field", aggregate_failures: true do
      model = Class.new(described_class)

      expect { model.zoho_field(:first_name) }.to change { model.zoho_fields.size }.by(1)
      expect(model.zoho_fields).to include(:first_name)
    end
  end

  describe ".zoho_enum" do
    it 'requires a "field_name" and a list of "elements"', aggregate_failures: true do
      model = Class.new(described_class)

      expect { model.zoho_enum }.to raise_error(ArgumentError)
      expect { model.zoho_enum(:status) }.to raise_error(ArgumentError)
      expect { model.zoho_enum(:status, elements: %w[enabled disabled]) }.to_not raise_error
    end

    it "defines a method with the given name" do
      model = Class.new(described_class) { zoho_enum(:status, elements: %w[enabled disabled]) }

      expect(model.method_defined?(:status)).to be(true)
    end

    it "adds a zoho field", aggregate_failures: true do
      model = Class.new(described_class)

      expect { model.zoho_enum(:status, elements: %w[enabled disabled]) }.to change { model.zoho_fields.size }.by(1)
      expect(model.zoho_fields).to include(:status)
    end
  end

  describe ".field" do
    context "when the field exists" do
      subject(:model) { Class.new(described_class) { zoho_field(:first_name) } }

      it "returns the field", aggregate_failures: true do
        field = model.field(:first_name)

        expect(field).to be_a(ZohoCRM::Fields::Field)
        expect(field.name).to eql("first_name")
      end
    end

    context "when the field does not exist" do
      subject(:model) { Class.new(described_class) }

      it "raises an error", aggregate_failures: true do
        expect { model.field(:first_name) }.to raise_error(ZohoCRM::FieldSet::FieldNotFoundError) do |error|
          expect(error.field_name).to eq(:first_name)
          expect(error.fields).to eq(model.zoho_fields)
          expect(error.message).to eq("Field not found: first_name")
        end
      end
    end
  end

  describe ".field?" do
    context "when the field exists" do
      subject(:model) { Class.new(described_class) { zoho_field(:first_name) } }

      it "returns true" do
        expect(model.field?(:first_name)).to be(true)
      end
    end

    context "when the field does not exist" do
      subject(:model) { Class.new(described_class) }

      it "returns false" do
        expect(model.field?(:first_name)).to be(false)
      end
    end
  end

  describe ".inspect" do
    before do
      MyZohoModel = Class.new(described_class) {
        zoho_module("CustomModule")
        zoho_field(:email)
      }
    end

    after do
      Object.send(:remove_const, :MyZohoModel)
    end

    it "returns a human-readable representation of the model class" do
      expect(MyZohoModel.inspect).to match(/\A#<MyZohoModel < #{described_class.name} zoho_module_name: "CustomModule" fields: .+>\z/)
    end
  end

  describe "#initialize" do
    it "requires an object as argument", aggregate_failures: true do
      model = Class.new(described_class)

      expect { model.new }.to raise_error(ArgumentError)
      expect { model.new(Object.new) }.to_not raise_error
    end

    it "sets the :object attribute" do
      model = Class.new(described_class)
      object = Object.new
      instance = model.new(object)

      expect(instance.object).to eq(object)
    end

    it "duplicates the fields defined on the class", aggregate_failures: true do
      model = Class.new(described_class) { zoho_field(:email, as: "Email") }
      object = Object.new
      instance = model.new(object)

      expect(instance.zoho_fields).to eq(model.zoho_fields)
      expect(instance.zoho_fields.object_id).to_not eq(model.zoho_fields.object_id)
    end
  end

  describe "#clone" do
    before do
      MyZohoModel = Class.new(described_class) {
        zoho_module("CustomModule")
        zoho_field(:first_name)
      }
    end

    after do
      Object.send(:remove_const, :MyZohoModel)
    end

    it "doesn't clone the object" do
      object = Object.new
      original_instance = MyZohoModel.new(object)
      cloned_instance = original_instance.clone

      expect(cloned_instance.object.object_id).to eq(original_instance.object.object_id)
    end

    it "clones the zoho fields", aggregate_failures: true do
      object = Object.new
      original_instance = MyZohoModel.new(object)
      original_instance.field(:first_name).value = "Sabine"
      cloned_instance = original_instance.clone

      original_first_name = original_instance.field(:first_name).value_for(object)
      cloned_first_name = cloned_instance.field(:first_name).value_for(object)

      expect(cloned_instance.zoho_fields).to eq(original_instance.zoho_fields)
      expect(cloned_instance.zoho_fields.object_id).to_not eq(original_instance.zoho_fields.object_id)

      expect(original_first_name).to eq("Sabine")
      expect(original_first_name).to be_frozen

      expect(cloned_first_name).to eq("Sabine")
      expect(cloned_first_name).to be_frozen

      expect(cloned_first_name.object_id).to_not eq(original_first_name.object_id)
    end
  end

  describe "#dup" do
    before do
      MyZohoModel = Class.new(described_class) {
        zoho_module("CustomModule")
        zoho_field(:first_name)
      }

      MyUser = Struct.new(:first_name)
    end

    after do
      Object.send(:remove_const, :MyZohoModel)
      Object.send(:remove_const, :MyUser)
    end

    it "doesn't duplicate the object" do
      object = MyUser.new("Yamanikto")
      original_instance = MyZohoModel.new(object)
      dupped_instance = original_instance.dup

      expect(dupped_instance.object.object_id).to eq(original_instance.object.object_id)
    end

    it "duplicates the zoho fields", aggregate_failures: true do
      object = MyUser.new("Yamanikto")
      original_instance = MyZohoModel.new(object)
      original_instance.field(:first_name).value = "Sabine"
      dupped_instance = original_instance.dup

      original_first_name = original_instance.field(:first_name).value_for(object)
      dupped_first_name = dupped_instance.field(:first_name).value_for(object)

      expect(dupped_instance.zoho_fields).to eq(original_instance.zoho_fields)
      expect(dupped_instance.zoho_fields.object_id).to_not eq(original_instance.zoho_fields.object_id)

      expect(original_first_name).to eq("Sabine")
      expect(dupped_first_name).to eq("Yamanikto")

      expect(dupped_first_name.object_id).to_not eq(original_first_name.object_id)
    end
  end

  describe "#zoho_fields" do
    let(:model) { Class.new(described_class) { zoho_field(:first_name) } }

    it "a copy of the class' zoho_fields", aggregate_failures: true do
      instance = model.new(Object.new)

      expect(instance.zoho_fields).to eq(model.zoho_fields)
      expect(instance.zoho_fields.object_id).to_not eq(model.zoho_fields.object_id)
    end
  end

  describe "#field" do
    context "when the field exists" do
      let(:model) { Class.new(described_class) { zoho_field(:first_name) } }

      it "returns the field", aggregate_failures: true do
        instance = model.new(Object.new)
        field = instance.field(:first_name)

        expect(field).to be_a(ZohoCRM::Fields::Field)
        expect(field.name).to eql("first_name")
      end
    end

    context "when the field does not exist" do
      let(:model) { Class.new(described_class) }

      it "raises an error", aggregate_failures: true do
        instance = model.new(Object.new)

        expect { instance.field(:first_name) }.to raise_error(ZohoCRM::FieldSet::FieldNotFoundError) do |error|
          expect(error.field_name).to eq(:first_name)
          expect(error.fields).to eq(model.zoho_fields)
          expect(error.message).to eq("Field not found: first_name")
        end
      end
    end
  end

  describe "#field?" do
    context "when the field exists" do
      let(:model) { Class.new(described_class) { zoho_field(:first_name) } }

      it "returns true" do
        instance = model.new(Object.new)

        expect(instance.field?(:first_name)).to be(true)
      end
    end

    context "when the field does not exist" do
      let(:model) { Class.new(described_class) }

      it "returns false" do
        instance = model.new(Object.new)

        expect(instance.field?(:first_name)).to be(false)
      end
    end
  end

  describe "#zoho_module" do
    context "when there is a :zoho_module_name" do
      it "returns the value of :zoho_module_name" do
        MyZohoModel = Class.new(described_class) { zoho_module("ZohoStuff") }
        model = MyZohoModel.new(double)

        expect(model.zoho_module).to eq("ZohoStuff")

        Object.send(:remove_const, :MyZohoModel)
      end
    end

    context "when there is no :zoho_module_name" do
      it "returns a String representation of the class name" do
        MyZohoModel = Class.new(described_class)
        model = MyZohoModel.new(double)

        expect(model.zoho_module).to eq("MyZohoModel")

        Object.send(:remove_const, :MyZohoModel)
      end

      it "returns the class name without its namespacing" do
        MyZohoNamespace = Module.new
        MyZohoNamespace::MyZohoModel = Class.new(described_class)
        model = MyZohoNamespace::MyZohoModel.new(double)

        expect(model.zoho_module).to eq("MyZohoModel")

        MyZohoNamespace.send(:remove_const, :MyZohoModel)
        Object.send(:remove_const, :MyZohoNamespace)
      end
    end
  end

  describe "#as_json" do
    before do
      MyZohoModel = Class.new(described_class) {
        zoho_field(:email, as: "Email")
        zoho_field(:full_name, as: "Full_Name")
      }

      MyUser = Struct.new(:email, :full_name, keyword_init: true)
    end

    after do
      Object.send(:remove_const, :MyZohoModel)
      Object.send(:remove_const, :MyUser)
    end

    it "returns the JSON representation of model as a Ruby Hash" do
      user = MyUser.new(email: "user@example.com", full_name: "Yoo Zerr")
      instance = MyZohoModel.new(user)

      expect(instance.as_json).to be_a(Hash).and eq({
        "Email" => "user@example.com",
        "Full_Name" => "Yoo Zerr",
      })
    end
  end

  describe "#to_json" do
    before do
      MyZohoModel = Class.new(described_class) {
        zoho_field(:email, as: "Email")
        zoho_field(:full_name, as: "Full_Name")
      }

      MyUser = Struct.new(:email, :full_name, keyword_init: true)
    end

    after do
      Object.send(:remove_const, :MyZohoModel)
      Object.send(:remove_const, :MyUser)
    end

    it "returns the JSON representation of model" do
      user = MyUser.new(email: "user@example.com", full_name: "Yoo Zerr")
      instance = MyZohoModel.new(user)

      expect(instance.to_json).to be_a(String).and eq('{"Email":"user@example.com","Full_Name":"Yoo Zerr"}')
    end
  end

  describe "#inspect" do
    before do
      MyZohoModel = Class.new(described_class) {
        zoho_module("CustomModule")
        zoho_field(:string, :to_s)
      }
    end

    after do
      Object.send(:remove_const, :MyZohoModel)
    end

    it "returns a human-readable representation of the model class" do
      object = Object.new
      instance = MyZohoModel.new(object)
      regex =
        /
          \A\#<MyZohoModel:#{instance.object_id}
          \ zoho_module:\ "CustomModule"
          \ object:\ #{Regexp.escape(object.inspect)}
          \ fields:\ .+>\z
        /x

      expect(instance.inspect).to match(regex)
    end
  end

  describe "#method_missing" do
    context "when the method name ends with '='" do
      context "when the method name matches a field" do
        before do
          MyZohoModel = Class.new(described_class) {
            zoho_field(:email, as: "Email")
          }

          MyUser = Struct.new(:email)
        end

        after do
          Object.send(:remove_const, :MyZohoModel)
          Object.send(:remove_const, :MyUser)
        end

        it "sets the static value of the field" do
          user = MyUser.new("user@example.com")
          instance = MyZohoModel.new(user)

          expect { instance.email = "john@example.com" }
            .to change { instance.field(:email).value_for(user) }
            .from("user@example.com").to("john@example.com")
        end
      end
    end
  end

  describe "#respond_to_missing?" do
    context "when the method name ends with '='" do
      context "when the method name matches a field" do
        before do
          MyZohoModel = Class.new(described_class) {
            zoho_field(:email, as: "Email")
          }

          MyUser = Struct.new(:email)
        end

        after do
          Object.send(:remove_const, :MyZohoModel)
          Object.send(:remove_const, :MyUser)
        end

        it "returns true" do
          user = MyUser.new("user@example.com")
          instance = MyZohoModel.new(user)

          expect(instance).to respond_to(:email=)
        end
      end
    end
  end
end
