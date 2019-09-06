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

      def initialize(field_name, field_method = nil, **options, &block)
        @options = ZohoCRM::Utils.normalize_options(options)

        self.name = field_name
        infer_api_name!

        self.api_name = @options.delete("as")

        self.field_method = block_given? ? block : field_method || name

        self.label = @options.delete("label")
      end

      # @param original_field [ZohoCRM::Fields::Field]
      # @return [ZohoCRM::Fields::Field]
      def initialize_clone(original_field)
        super

        %i[@name @field_method @label @api_name @inferred_api_name @options].each do |ivar|
          original_ivar = original_field.instance_variable_get(ivar)

          instance_variable_set(ivar, ZohoCRM::Utils::Copiable.deep_clone(original_ivar))
        end

        if original_field.instance_variable_defined?(:@static_value)
          original_static_value = ZohoCRM::Utils::Copiable.deep_clone(original_field.instance_variable_get(:@static_value))

          instance_variable_set(:@static_value, original_static_value)
        else
          instance_variable_set(:@static_value, nil)
        end
      end

      # @param original_field [ZohoCRM::Fields::Field]
      # @return [ZohoCRM::Fields::Field]
      def initialize_dup(original_field)
        super

        %i[@name @field_method @label @api_name @inferred_api_name @options].each do |ivar|
          original_ivar = original_field.instance_variable_get(ivar)

          instance_variable_set(ivar, ZohoCRM::Utils::Copiable.deep_dup(original_ivar))
        end

        instance_variable_set(:@static_value, nil)
      end

      def api_name=(value)
        string_value = value.to_s.strip
        @api_name = value && !string_value.empty? ? string_value : inferred_api_name
      end

      def label=(value)
        string_value = value.to_s.strip
        @label = value && !string_value.empty? ? string_value : api_name.tr("_", " ")
      end

      # Sets a static value for the field
      def value=(value)
        @static_value = value
      end

      # @raise [ZohoCRM::Fields::Field::UnsupportedMethodTypeError]
      def value_for(object)
        unless static_value.nil?
          return static_value
        end

        case field_method
        when Symbol, String
          object.public_send(field_method)
        when Proc
          case field_method.arity
          when 0
            object.instance_exec(&field_method)
          when 1
            object.instance_exec(object, &field_method)
          when 2
            object.instance_exec(object, clone.freeze, &field_method)
          else
            warn("warning: too many arguments given to block (expected 0...2, got #{field_method.arity.inspect})")

            object.instance_exec(
              object,
              clone.freeze,
              *Array.new(field_method.arity - 2),
              &field_method
            )
          end
        else
          # Note: This should not happen, but anything is possible in Ruby
          raise UnsupportedMethodTypeError.new(field_method)
        end
      end

      # Returns +true+ if the field has non-+nil+ static value, +false+ otherwise.
      #
      # - Returns +true+ if the field has a static value that is not +nil+.
      # - Returns +false+ if the field has a static value that is +nil+.
      # - Returns +false+ if the field doesn't has a static value.
      def static?
        !static_value.nil?
      end

      # @return [false]
      def enum?
        false
      end

      # @return [Integer]
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

      # Returns a string containing a human-readable representation of the field.
      #
      # @example
      #   ZohoCRM::Fields::Field.new(:email).inspect
      #   # => #<ZohoCRM::Fields::Field name: "email" api_name: "Email" field_method: "email" options: {}>
      #
      # @return [String]
      def inspect
        format("#<%s name: %p api_name: %p field_method: %s options: %p>",
          self.class.name, name, api_name, inspect_field_method, options)
      end

      protected

      attr_reader :static_value

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
