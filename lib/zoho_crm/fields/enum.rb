# frozen_string_literal: true

module ZohoCRM
  module Fields
    class Enum < Field
      class InvalidValueError < KeyError
        attr_reader :enum
        attr_reader :value

        def initialize(enum:, value:)
          @enum = enum
          @value = value

          message = "Invalid value #{value.inspect} for enum: #{enum.human_readable_elements}"

          # In Ruby 2.6+ KeyError#initialize take three arguments:
          #
          #   super(message, receiver: enum.elements, key: value)
          #
          # Prior versions only accepted the message as argument.
          super(message)
        end
      end

      attr_reader :elements

      # *Caveat:* Options are parsed as keyword arguments, so all the keys must be symbols (not strings)
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

      # @raise [ZohoCRM::Fields::Enum::FieldNotFoundError] if the value is not a valid element.
      def value_for(object)
        value = super(object)

        unless element?(value)
          raise InvalidValueError.new(enum: self, value: value)
        end

        element(value)
      end

      # @return [true]
      def enum?
        true
      end

      def element?(value)
        elements.key?(value.to_s) || elements.value?(value)
      end

      def element(value)
        return unless element?(value)

        elements.fetch(value.to_s, value)
      end

      def human_readable_elements
        human_elements = elements.map { |(k, v)| "#{k.inspect} (#{v.inspect})" }
        "[#{human_elements.join(", ")}]"
      end

      def inspect
        format("#<%s name: %p api_name: %p field_method: %p elements: %s options: %p>",
          self.class.name, name, api_name, field_method, human_readable_elements, options)
      end

      private

      def normalize_elements(value)
        case value
        when Array
          values = value.compact.uniq
          normalize_elements(Hash[values.zip(values)])
        when Hash
          Hash[value.map { |(k, v)| [String(k), v] }]
        else
          normalize_elements(Array(value))
        end
      end
    end
  end
end
