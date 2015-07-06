module EbayTrading
  module DeepFind

    # Recursively deep search through the a nested +hash+ and return the
    # first value matching the +path+ of node names.
    # If +path+ cannot be matched the value of +default+ is returned.
    # @param [Hash] hash the Hash to recursively deep searched.
    # @param [Array [String|Symbol]] path an array of the keys defining the path to the node of interest.
    # @param [Object] default the value to be returned if +path+ cannot be matched.
    # @return [Object] the first value found in +path+, or +default+.
    #
    def deep_find(hash, path, default = nil)
      return default unless hash && hash.is_a?(Hash)
      return default unless path
      @deep_find_mutex = Mutex.new unless @deep_find_mutex
      @deep_find_mutex.synchronize do
        path = [path] if path.is_a?(String) || path.is_a?(Symbol)
        return default unless path.is_a?(Array) && !path.empty?
        location = hash
        path.each do |key|
          return default if location.nil? || !location.key?(key)
          location = location[key]
        end
        return location
      end
    end

  end
end