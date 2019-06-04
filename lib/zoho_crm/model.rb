# frozen_string_literal: true

module ZohoCRM
  class Model
    extend Forwardable

    class << self
      attr_reader :zoho_module_name

      def zoho_module(module_name)
        module_name = module_name.to_s
        @zoho_module_name = module_name.empty? ? nil : module_name
      end

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

      def zoho_enum(name, elements, field_method = nil, **options, &block)
        field = ZohoCRM::Fields::Enum.new(name, elements, field_method, **options, &block)

        unless method_defined?(field.name)
          define_method(field.name) { value_for(field) }
        end

        zoho_fields.add(field)
      end

      def field(name)
        zoho_fields.fetch(name)
      end

      def field?(name)
        zoho_fields.include?(name)
      end

      def inspect
        format("#<%s < %s zoho_module_name: %p fields: %p>", name, superclass.name, zoho_module_name, zoho_fields)
      end
    end

    def_delegators :'self.class', :zoho_fields, :field, :field?

    attr_reader :object

    def initialize(object)
      @object = object
    end

    def zoho_module
      self.class.zoho_module_name || default_zoho_module_name
    end

    def as_json
      zoho_fields.each_with_object({}) do |field, obj|
        obj[field.api_name.to_s] = ZohoCRM::Utils.jsonify(field.value_for(object))
      end
    end

    def to_json
      JSON.generate(as_json)
    end

    def inspect
      format("#<%s:%s zoho_module: %p object: %p fields: %p>",
        self.class.name, object_id, zoho_module, object, zoho_fields)
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
