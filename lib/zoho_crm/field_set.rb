# frozen_string_literal: true

module ZohoCRM
  class FieldSet
    class FieldNotFoundError < KeyError
      attr_reader :field_name
      attr_reader :fields

      def initialize(field_name, fields:)
        @field_name = field_name
        @fields = fields

        message = "Field not found: #{@field_name}"

        # In Ruby 2.6+ KeyError#initialize take three arguments:
        #
        #   super(message, receiver: @fields, key: @field_name)
        #
        # Prior versions only accepted the message as argument.
        super(message)
      end
    end

    include Enumerable

    def initialize
      @hash = {}
    end

    # @param field [Symbol, String, ZohoCRM::Fields::Field] field name or field instance
    #
    # @return [nil, ZohoCRM::Fields::Field]
    def [](field)
      key = key_for(field)

      key.nil? ? nil : @hash[key]
    end

    # @param field [Symbol, String, ZohoCRM::Fields::Field] field name or field instance
    # @param default [ZohoCRM::Fields::Field] default value if no field is found
    #
    # @yieldparam field [Symbol, String, ZohoCRM::Fields::Field] field name or field instance
    # @yieldreturn [ZohoCRM::Fields::Field]
    #
    # @note If a block *and* a default value are passed then the block supersedes the default value argument
    #
    # @return [ZohoCRM::Fields::Field]
    #
    # @raise [ZohoCRM::FieldSet::FieldNotFoundError]
    def fetch(field, default = nil)
      if block_given? && !default.nil?
        warn("warning: block supersedes default value argument")
      end

      key = key_for(field)

      if key.nil?
        raise FieldNotFoundError.new(field, fields: self)
      end

      @hash.fetch(key) do
        if block_given?
          yield(field)
        elsif !default.nil?
          default
        else
          raise FieldNotFoundError.new(field, fields: self)
        end
      end
    end

    # Add a field to the fieldset.
    #
    # @param field [ZohoCRM::Fields::Field]
    #
    # @return [ZohoCRM::Fields::Field]
    #
    # @raise [TypeError] if +field+ is not a {ZohoCRM::Fields::Field}
    def add(field)
      raise TypeError unless field.is_a?(ZohoCRM::Fields::Field)

      unless include?(field)
        @hash[field.name] = field
      end

      field
    end

    # Add a field to the fieldset (chainable).
    #
    # Unlike {#add}, this method is chainable.
    #
    # @example
    #   field_set = ZohoCRM::FieldSet.new
    #   field_set << ZohoCRM::Fields::Field.new(:email) << ZohoCRM::Fields::Field.new(:name)
    #   # => field_set
    #   field_set.size
    #   # => 2
    #
    # @param field [ZohoCRM::Fields::Field]
    #
    # @return [self]
    #
    # @raise [TypeError] if +field+ is not a {ZohoCRM::Fields::Field}
    def <<(field)
      raise TypeError unless field.is_a?(ZohoCRM::Fields::Field)

      unless include?(field)
        @hash[field.name] = field
      end

      self
    end

    # @param field [Symbol, String, ZohoCRM::Fields::Field] field name or field instance
    def include?(other)
      key = key_for(other)

      key.nil? ? false : @hash.include?(key)
    end
    alias member? include?

    # @return [self, Enumerator]
    def each(&block)
      unless block_given?
        return enum_for(__method__) { size }
      end

      @hash.each_value(&block)

      self
    end

    # Returns the number of elements.
    #
    # @return [Integer]
    def size
      @hash.size
    end
    alias length size

    # Returns +true+ if the set contains no elements.
    def empty?
      @hash.empty?
    end

    # Removes all elements.
    #
    # @return [self]
    def clear
      @hash.clear
      self
    end

    # Converts the set to an +Array+.
    #
    # @note The order of elements is uncertain.
    #
    # @return [Array]
    def to_a
      @hash.values
    end

    # @return [Hash]
    def to_h
      @hash
    end

    # Deletes the given object from the set.
    #
    # @yieldparam field [Symbol, String, ZohoCRM::Fields::Field]
    #
    # @return [self]
    def delete(other)
      key = key_for(other)

      @hash.delete(key) unless key.nil?

      self
    end

    # Deletes every element of the set for which block evaluates to +true+
    #
    # Returns an +Enumerator+ if no block is given, +self+ otherwise.
    #
    # @yieldparam field [Symbol, String, ZohoCRM::Fields::Field]
    #
    # @return [self, Enumerator]
    def delete_if
      unless block_given?
        return enum_for(__method__) { size }
      end

      select { |field| yield(field) }.each { |field| delete(field) }

      self
    end

    # Deletes every element of the set for which block evaluates to +false+.
    #
    # Returns an +Enumerator+ if no block is given, +self+ otherwise.
    #
    # @yieldparam field [Symbol, String, ZohoCRM::Fields::Field]
    #
    # @return [self, Enumerator]
    def keep_if
      unless block_given?
        return enum_for(__method__) { size }
      end

      reject { |field| yield(field) }.each { |field| delete(field) }

      self
    end

    # @return [Integer]
    def hash
      @hash.hash
    end

    # Returns +false+ if +other+ is not a {ZohoCRM::FieldSet}
    #
    # Returns +true+ if +other+ and +self+ are the same object or have the same contents.
    def eql?(other)
      return false unless other.is_a?(FieldSet)

      other.equal?(self) || other.instance_variable_get(:@hash).eql?(@hash)
    end

    # Returns +false+ if +other+ is not a {ZohoCRM::FieldSet}.
    #
    # Returns +true+ if two sets are equal. The equality of each couple of elements is
    # defined according to {Object#==}[https://ruby-doc.org/core-2.6.3/Object.html#method-i-eql-3F].
    #
    # @return [Boolean]
    def ==(other)
      if other.equal?(self)
        true
      elsif other.instance_of?(self.class)
        other.instance_variable_get(:@hash) == @hash
      elsif other.is_a?(FieldSet) && other.size == size
        other.all? { |field| field == self[field] }
      else
        false
      end
    end

    # @!visibility private
    def freeze
      @hash.freeze
      super
    end

    # @!visibility private
    def taint
      @hash.taint
      super
    end

    # @!visibility private
    def untaint
      @hash.untaint
      super
    end

    # Returns a string containing a human-readable representation of the fieldset.
    #
    # @example
    #   fieldset = ZohoCRM::FieldSet.new
    #   fieldset.inspect
    #   # => #<ZohoCRM::FieldSet ()>
    #   fieldset << ZohoCRM::Fields::Field.new(:email)
    #   fieldset << ZohoCRM::Fields::Enum.new(:status, %i[enabled disabled])
    #   fieldset.inspect
    #   # => #<ZohoCRM::FieldSet: (email: #<ZohoCRM::Fields::Field ...> status: #<ZohoCRM::Fields::Enum ...>)>
    #
    # @return [String]
    #
    # @see ZohoCRM::Fields::Field#inspect
    # @see ZohoCRM::Fields::Enum#inspect
    def inspect
      fields_inspect_string = @hash.each_value.map { |f| "#{f.name}: #{f.inspect}" }.join(" ")
      format("#<%s (%s)>", self.class.name, fields_inspect_string)
    end

    private

    def key_for(other)
      case other
      when Symbol
        other.to_s
      when String
        other
      when ZohoCRM::Fields::Field
        other.name
      end
    end
  end
end
