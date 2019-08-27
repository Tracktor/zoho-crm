# frozen_string_literal: true

module ZohoCRM
  module Utils
    module Copiable
      # Deep clone any object.
      #
      # @param object [Object] Pretty much anything.
      # @param cache  [Hash]   Cache +object_id+s to prevent stack overflow on
      #                        recursive data structures.
      #
      # @return [Object] Cloned object if possible.
      def self.deep_clone(object, cache = {})
        unless clonable?(object)
          return object
        end

        case object
        when Array
          cache_object(object, [], cache) do |new_object|
            object.each do |item|
              new_object << deep_clone(item, cache)
            end
          end
        when Hash
          cache_object(object, {}, cache) do |new_object|
            object.each do |key, value|
              new_object[deep_clone(key, cache)] = deep_clone(value, cache)
            end
          end
        else
          object.clone
        end
      end

      # Deep duplicate any object.
      #
      # @param object [Object] Pretty much anything.
      # @param cache  [Hash]   Cache +object_id+s to prevent stack overflow on
      #                        recursive data structures.
      #
      # @return [Object] Dupped object if possible.
      def self.deep_dup(object, cache = {})
        unless duplicable?(object)
          return object
        end

        case object
        when Array
          cache_object(object, [], cache) do |new_object|
            object.each do |item|
              new_object << deep_dup(item, cache)
            end
          end
        when Hash
          cache_object(object, {}, cache) do |new_object|
            object.each do |key, value|
              new_object[deep_dup(key, cache)] = deep_dup(value, cache)
            end
          end
        else
          object.dup
        end
      end

      # Prevent infinite recursion on recursive data structures.
      #
      # Imagine an array that has only one item which is a reference to itself.
      # When entering this method, the cache is empty so we create a new array
      # and map the original object's id to this newly created object.
      #
      # We then give control back to +deep_dup+ so that it can go on and do the
      # adding, which will call itself with the same array and enter this method
      # again.
      #
      # But this time, since the object is the same, we know the duplicate object
      # because we stored in in our little cache. So just go ahead and return it
      # otherwise it would result in an infinite recursion.
      #
      # @param object     [Array, Hash] Original object reference.
      # @param new_object [Array, Hash] The dupped object reference.
      # @param cache      [Hash]        Map from original object_id to dupped object.
      #
      # @yieldparam new_object [Array, Hash] The dupped object reference.
      #
      # @return [Array, Hash] The dupped object.
      def self.cache_object(object, new_object, cache)
        object_id = object.object_id

        if cache.key?(object_id)
          return cache[object_id]
        end

        cache[object_id] = new_object

        yield(new_object)

        new_object
      end

      # @param object [Object]
      # @return [Boolean]
      def self.clonable?(object)
        case object
        when Symbol, NilClass, TrueClass, FalseClass, Integer, Float
          false
        else
          true
        end
      end

      # @param object [Object]
      # @return [Boolean]
      def self.duplicable?(object)
        case object
        when Symbol, NilClass, TrueClass, FalseClass, Integer, Float, Method
          false
        else
          true
        end
      end
    end
  end
end
