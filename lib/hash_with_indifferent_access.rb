require 'active_support/core_ext/hash/indifferent_access'

class HashWithIndifferentAccess

  # Perform a depth first search of this hash and return the first element
  # matching +path+, or +default+ if nothing found.
  # @param [Array[String | Symbol] | String | Symbol] path to the element of interest.
  # @param [Object] default the object to be returned if there is no result for +path+.
  # @return [Object] the first object found on +path+ or +default+.
  #
  def deep_find(path, default = nil)
    return default unless path
    path = [path] if path.is_a?(String) || path.is_a?(Symbol)
    return default unless path.is_a?(Array) && !path.empty?

    location = self
    path.each do |key|
      return default if location.nil? || !location.key?(key)
      location = location[key]
    end
    return location
  end
end