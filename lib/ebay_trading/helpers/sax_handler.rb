require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/string'

module EbayTrading
  class SaxHandler

    attr_accessor :stack
    attr_accessor :path

    def initialize
      @stack = []
      @stack.push(HashWithIndifferentAccess.new)
      @path = []
      @hash = nil
    end

    def to_hash
      stack[0]
    end

    def start_element(name)
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
      parent = @stack[-2]
      parent[key] = value
    end

    def cdata(value)
      key = path.last
      parent = @stack[-2]
      parent[key] = value
    end

    def attr(name, value)
      return if name.to_s.downcase == 'xmlns'
      append(name, value) unless @stack.empty?
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
        h[key] = value
      end
    end

    #-------------------------------------------------------------------------
    private

    def format_key(key)
      key.underscore
    end

  end
end
