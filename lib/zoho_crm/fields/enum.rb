# frozen_string_literal: true

module ZohoCRM
  module Fields
    class Enum < Field
      class InvalidValueError < KeyError
        def initialize(enum: nil, value: nil)
          message = "Invalid value #{value} for enum: #{enum.human_readable_elements}"
          super(message, receiver: enum.elements, key: value)
        end
      end

      attr_reader :elements

      # Caveat: options are parsed as keyword arguments,
      #         so all the keys must be symbols (not string)
      def self.build(field_name, field_method = nil, **options, &block)
        options = ZohoCRM::Utils.normalize_options(options)

        unless options.key?("values")
          raise ArgumentError, "'values' key not found in options: #{options.inspect}"
        end

        new(field_name, options.delete("values"), field_method, **options, &block)
      end

      # Note: This violates LSP (Liskov substitution principle)
      # but complying to it would add complexity with no gain.
      def initialize(field_name, elements, field_method = nil, **options, &block)
        super(field_name, field_method, **options, &block)

        @elements = normalize_elements(elements)
      end

      def value_for(object)
        value = super(object)

        unless elements.key?(value.to_s) || elements.value?(value)
          raise InvalidValueError.new(enum: self, value: value)
        end

        value
      end

      def enum?
        true
      end

      def clear
        @value = nil
      end

      def human_readable_elements
        elements.map { |(k, v)| "#{k.inspect} (#{v.inspect})" }
      end

      def inspect
        format("#<%s:%s name: %p api_name: %p field_method: %p elements: %p options: %p>",
          self.class.name, object_id, name, api_name, field_method, human_readable_elements, options)
      end

      private

      def normalize_elements(value)
        case value
        when Array
          values = value.compact.uniq
          Hash[values.map(&:to_s).zip(values)]
        when Hash
          value
        else
          normalize_elements(Array(value))
        end
      end
    end
  end
end
