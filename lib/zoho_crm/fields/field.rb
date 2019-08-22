# frozen_string_literal: true

module ZohoCRM
  module Fields
    class Field
      class UnsupportedMethodTypeError < TypeError
        SUPPORTED_METHOD_TYPES = [Symbol, String, Proc].freeze

        def initialize(object)
          message = "expected to receive one of #{SUPPORTED_METHOD_TYPES}" \
            " but received a #{object.class.name}: #{object.inspect}"
          super(message)
        end
      end

      attr_reader :name
      attr_reader :api_name
      attr_reader :label
      attr_reader :field_method
      attr_reader :options

      # *Caveat:* Options are parsed as keyword arguments, so all the keys must be symbols (not strings)
      def self.build(field_name, field_method = nil, **options, &block)
        if options.key?(:values)
          ZohoCRM::Fields::Enum.build(field_name, field_method, **options, &block)
        else
          new(field_name, field_method, **options, &block)
        end
      end

      def initialize(field_name, field_method = nil, **options, &block)
        @options = ZohoCRM::Utils.normalize_options(options)

        self.name = field_name
        infer_api_name!

        self.api_name = @options.delete("as")

        self.field_method = block_given? ? block : field_method || name

        self.label = @options.delete("label")
      end

      def api_name=(value)
        string_value = value.to_s.strip
        @api_name = value && !string_value.empty? ? string_value : inferred_api_name
      end

      def label=(value)
        string_value = value.to_s.strip
        @label = value && !string_value.empty? ? string_value : api_name.tr("_", " ")
      end

      # @raise [ZohoCRM::Fields::Field::UnsupportedMethodTypeError]
      def value_for(object)
        case field_method
        when Symbol, String
          object.public_send(field_method)
        when Proc
          if field_method.arity.positive?
            object.instance_exec(object, &field_method)
          else
            object.instance_exec(&field_method)
          end
        else
          # Note: This should not happen, but anything is possible in Ruby
          raise UnsupportedMethodTypeError.new(field_method)
        end
      end

      # @return [false]
      def enum?
        false
      end

      def hash
        name.hash
      end

      def eql?(other)
        case other
        when Field
          other.name == name
        when Symbol
          other.to_s.strip == name
        when String
          other.strip == name
        else
          false
        end
      end
      alias == eql?

      # @return [String]
      def inspect
        format("#<%s name: %p api_name: %p field_method: %s options: %p>",
          self.class.name, name, api_name, inspect_field_method, options)
      end

      private

      attr_reader :inferred_api_name

      def name=(value)
        string_value = value.to_s.strip

        unless value && !string_value.empty?
          raise ArgumentError, "name can't be blank"
        end

        @name = string_value
      end

      def infer_api_name!
        @inferred_api_name = name.gsub(/[^ _]+/) { |s| s.capitalize }
      end

      def field_method=(value)
        unless [Symbol, String, Proc].include?(value.class)
          raise UnsupportedMethodTypeError.new(value)
        end

        @field_method = value
      end

      def inspect_field_method
        case field_method
        when Proc
          "#<Proc:#{field_method.object_id}:#{field_method.hash}>"
        when Method
          field_method.name.inspect
        else
          field_method.inspect
        end
      end
    end
  end
end
