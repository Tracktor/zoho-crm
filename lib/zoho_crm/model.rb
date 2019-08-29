# frozen_string_literal: true

module ZohoCRM
  class Model
    class << self
      attr_reader :zoho_module_name

      def zoho_module(module_name)
        module_name = module_name.to_s
        @zoho_module_name = module_name.empty? ? nil : module_name
      end

      # @return [ZohoCRM::FieldSet]
      def zoho_fields
        @zoho_fields ||= FieldSet.new
      end

      def zoho_field(name, field_method = nil, **options, &block)
        field = ZohoCRM::Fields::Field.new(name, field_method, **options, &block)

        unless method_defined?(field.name)
          define_method(field.name) { value_for(field) }
        end

        zoho_fields.add(field)
      end

      def zoho_enum(name, field_method = nil, elements:, **options, &block)
        field = ZohoCRM::Fields::Enum.new(name, elements, field_method, **options, &block)

        unless method_defined?(field.name)
          define_method(field.name) { value_for(field) }
        end

        zoho_fields.add(field)
      end

      # Returns the field matching the +name+ argument or raise an error if it is not found.
      #
      # @param name [Symbol, String, ZohoCRM::Fields::Field] field name or field instance
      #
      # @return [ZohoCRM::Fields::Field]
      #
      # @raise [ZohoCRM::FieldSet::FieldNotFoundError]
      def field(name)
        zoho_fields.fetch(name)
      end

      # @param name [Symbol, String, ZohoCRM::Fields::Field] field name or field instance
      def field?(name)
        zoho_fields.include?(name)
      end

      # Returns a string containing a human-readable representation of the model class.
      #
      # @return [String]
      def inspect
        format("#<%s < %s zoho_module_name: %p fields: %p>", name, superclass.name, zoho_module_name, zoho_fields)
      end
    end

    attr_reader :object

    # @return [ZohoCRM::FieldSet]
    attr_reader :zoho_fields

    def initialize(object)
      @object = object
      @zoho_fields = ZohoCRM::Utils::Copiable.deep_dup(self.class.zoho_fields)
    end

    # @param original_model [ZohoCRM::Model]
    #
    # @return [ZohoCRM::Model]
    def initialize_clone(original_model)
      super

      original_zoho_fields = original_model.instance_variable_get(:@zoho_fields)

      instance_variable_set(:@zoho_fields, ZohoCRM::Utils::Copiable.deep_clone(original_zoho_fields))
    end

    # @param original_model [ZohoCRM::Model]
    #
    # @return [ZohoCRM::Model]
    def initialize_dup(original_model)
      super

      original_zoho_fields = original_model.instance_variable_get(:@zoho_fields)

      instance_variable_set(:@zoho_fields, ZohoCRM::Utils::Copiable.deep_dup(original_zoho_fields))
    end

    # @return [String] The name of the Zoho module
    def zoho_module
      self.class.zoho_module_name || default_zoho_module_name
    end

    # Returns the field matching the +name+ argument or raise an error if it is not found.
    #
    # @param name [Symbol, String, ZohoCRM::Fields::Field] field name or field instance
    #
    # @return [ZohoCRM::Fields::Field]
    #
    # @raise [ZohoCRM::FieldSet::FieldNotFoundError]
    def field(name)
      zoho_fields.fetch(name)
    end

    # @param name [Symbol, String, ZohoCRM::Fields::Field] field name or field instance
    def field?(name)
      zoho_fields.include?(name)
    end

    # @return [Hash]
    def as_json
      zoho_fields.each_with_object({}) do |field, obj|
        obj[field.api_name.to_s] = ZohoCRM::Utils.jsonify(field.value_for(object))
      end
    end

    # @return [String]
    def to_json
      JSON.generate(as_json)
    end

    # Returns a string containing a human-readable representation of the model instance.
    #
    # @return [String]
    def inspect
      format("#<%s:%s zoho_module: %p object: %p fields: %p>",
        self.class.name, object_id, zoho_module, object, zoho_fields)
    end

    # @!visibility private
    def method_missing(method_name, *args, &block)
      if method_name.to_s.end_with?("=") && field?(method_name.to_s.slice(0...-1))
        f = field(method_name.to_s.slice(0...-1))
        f.value = args.first
      else
        super
      end
    end

    # @!visibility private
    def respond_to_missing?(method_name, *args)
      (method_name.to_s.end_with?("=") && field?(method_name.to_s.slice(0...-1))) || super
    end

    protected

    def default_zoho_module_name
      @default_zoho_module_name ||= self.class.name.gsub(/\A.*::/, "")
    end

    def value_for(field)
      field.value_for(object)
    end
  end
end
