# frozen_string_literal: true

#require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/string'
require 'hash_with_indifferent_access'

module EbayTrader
  class SaxHandler

    attr_accessor :stack
    attr_accessor :path
    attr_reader :skip_type_casting
    attr_reader :known_arrays

    def initialize(args = {})
      @stack = []
      @stack.push(HashWithIndifferentAccess.new)
      @path = []
      @hash = nil
      @attributes = {}

      @skip_type_casting = args[:skip_type_casting] || []
      @skip_type_casting = [@skip_type_casting] unless @skip_type_casting.is_a?(Array)
      @skip_type_casting.map! { |key| format(key.to_s) }

      @known_arrays = args[:known_arrays] || []
      @known_arrays = [@known_arrays] unless @known_arrays.is_a?(Array)
      @known_arrays.map! { |key| format(key.to_s) }
    end

    def to_hash
      stack[0]
    end

    def start_element(name)
      @attributes.clear
      name = name.to_s
      path.push(name)

      hash = HashWithIndifferentAccess.new
      append(format_key(name), hash)
      stack.push(hash)
    end

    def end_element(_)
      @stack.pop
      @path.pop
    end

    def text(value)
      key = format_key(path.last)
      auto_cast = !(skip_type_casting.include?(path.last) || skip_type_casting.include?(key.to_s))
      parent = @stack[-2]

      # If 'CurrencyID' is a defined attribute we are dealing with money type
      if @attributes.key?('CurrencyID')
        currency = @attributes.delete('CurrencyID')
        value = BigDecimal.new(value)
        if EbayTrader.configuration.price_type == :money && EbayTrader.is_money_gem_installed?
          value = Money.new((value * 100).round.to_i, currency)
        else
          @attributes['Currency'] = currency
          value = value.to_f if EbayTrader.configuration.price_type == :float
          value = (value * 100).round.to_i if EbayTrader.configuration.price_type == :fixnum
        end
      end

      if auto_cast && value.is_a?(String)
        case
          when value.downcase == 'false' then value = false
          when value.downcase == 'true'  then value = true
          when value.match(/^[0-9]+$/) then value = value.to_i
          when value.match(/^[0-9]+[.][0-9]+$/) then value = value.to_f
          when value.match(/^[0-9]{4}-[0-9]{2}-[0-9]{2}[T ][0-9]{2}:[0-9]{2}:[0-9]{2}(.[0-9a-z]+)?$/i)
            value = Time.parse(value)
        end
      end

      if parent[key].is_a?(Array)
        parent[key].pop if parent[key].last.is_a?(Hash) && parent[key].last.empty?
        parent[key] << value
      else
        parent[key] = value
      end

      unless @attributes.empty?
        @attributes.each_pair do |attr_key, attr_value|
          attr_key_element_name = format_key("#{path.last}#{attr_key}")
          parent[attr_key_element_name] = attr_value
        end
      end
    end

    def cdata(value)
      key = format_key(path.last)
      parent = @stack[-2]
      parent[key] = value
    end

    def attr(name, value)
      return if name.to_s.downcase == 'xmlns'
      last = path.last
      return if last.nil?

      name = name[0].upcase + name[1...name.length]
      @attributes[name] = value
    end

    def error(message, line, column)
      raise Exception.new("#{message} at #{line}:#{column}")
    end

    def append(key, value)
      key = key.to_s
      h = @stack.last
      if h.key?(key)
        v = h[key]
        if v.is_a?(Array)
          v << value
        else
          h[key] = [v, value]
        end
      else
        if known_arrays.include?(key)
          h[key] = [value]
        else
          h[key] = value
        end
      end
    end

    #-------------------------------------------------------------------------
    private

    # Ensure the key is an underscored Symbol.
    #
    # Examples:
    #
    #     'ApplyBuyerProtection' -> :apply_buyer_protection
    #     'PayPalEmailAddress'   -> :paypal_email_address
    #     'SoldOffeBay'          -> :sold_off_ebay
    #
    # @return [Symbol] the reformatted key.
    #
    def format_key(key)
      key = key.to_s
      key = key.gsub('PayPal', 'Paypal')
      key = key.gsub('eBay',   'Ebay')
      key = key.gsub('EBay',   'Ebay')
      key.underscore.to_sym
    end
  end
end
