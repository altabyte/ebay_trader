$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'ebay_trading'

# Add 'include FileToString' to spec files requiring this functionality.
module FileToString
  def file_to_string(file_path)
    string = File.open(file_path, 'r') { |f| f.read }
    return string
  end
end

