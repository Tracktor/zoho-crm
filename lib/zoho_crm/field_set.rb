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

    # @return [nil, object]
    def [](field)
      key = key_for(field)

      key.nil? ? nil : @hash[key]
    end

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

    # @raise [TypeError] if +field+ is not a {ZohoCRM::Fields::Field}
    #
    # @return [self]
    def add(field)
      raise TypeError unless field.is_a?(ZohoCRM::Fields::Field)

      unless include?(field)
        @hash[field.name] = field
      end

      self
    end
    alias << add

    def include?(other)
      key = key_for(other)

      key.nil? ? false : @hash.include?(key)
    end
    alias member? include?

    # @return [self]
    def each(&block)
      unless block_given?
        return enum_for(__method__) { size }
      end

      @hash.each_value(&block)

      self
    end

    # Returns the number of elements.
    def size
      @hash.size
    end
    alias length size

    # Returns +true+ if the set contains no elements.
    def empty?
      @hash.empty?
    end

    # Removes all elements and returns +self+.
    #
    # @return [self]
    def clear
      @hash.clear
      self
    end

    # Converts the set to an +Array+.  The order of elements is uncertain.
    def to_a
      @hash.values
    end

    def to_h
      @hash
    end

    # Deletes the given object from the set and returns +self+.
    #
    # @return [self]
    def delete(other)
      key = key_for(other)

      @hash.delete(key) unless key.nil?

      self
    end

    # Deletes every element of the set for which block evaluates to
    # +true+, and returns +self+. Returns an +Enumerator+ if no block is
    # given.
    #
    # @return [self]
    def delete_if
      unless block_given?
        return enum_for(__method__) { size }
      end

      select { |field| yield(field) }.each { |field| delete(field) }

      self
    end

    # Deletes every element of the set for which block evaluates to
    # +false+, and returns +self+. Returns an +Enumerator+ if no block is
    # given.
    #
    # @return [self]
    def keep_if
      unless block_given?
        return enum_for(__method__) { size }
      end

      reject { |field| yield(field) }.each { |field| delete(field) }

      self
    end

    def hash
      @hash.hash
    end

    def eql?(other)
      return false unless other.is_a?(FieldSet)

      other.equal?(self) || other.instance_variable_get(:@hash).eql?(@hash)
    end

    # Returns +true+ if two sets are equal. The equality of each couple
    # of elements is defined according to +Object#==+.
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

    def freeze
      @hash.freeze
      super
    end

    def taint
      @hash.taint
      super
    end

    def untaint
      @hash.untaint
      super
    end

    # @return [String]
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
