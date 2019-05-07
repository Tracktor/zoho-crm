# frozen_string_literal: true

module ZohoCRM
  module Utils
    def self.normalize_options(options)
      unless options.respond_to?(:to_h)
        raise TypeError, "no implicit conversion of #{options.class} into Hash"
      end

      options.to_h.each_with_object({}) do |(key, value), obj|
        string_value = value.to_s.strip

        next unless value && !string_value.empty?

        obj[key.to_s] = string_value
      end
    end

    def self.jsonify(value)
      case value
      when Symbol
        value.to_s
      when Float
        value.finite? ? value : nil
      when BigDecimal
        value.finite? ? value.to_s : nil
      when Array
        value.map { |el| jsonify(el) }
      when Hash
        Hash[value.map { |k, v| [k.to_s, jsonify(v)] }]
      when Enumerable
        jsonify(value.to_a)
      when Time, Date, DateTime
        value.iso8601
      else
        value
      end
    end
  end
end
