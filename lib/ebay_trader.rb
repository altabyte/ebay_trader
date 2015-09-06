require 'ebay_trader/version'
require 'ebay_trader/configuration'

module EbayTrader

  # Generic runtime error for this gem.
  #
  class EbayTraderError < RuntimeError; end

  # The error raised when the HTTP connection times out.
  #
  # *Note:* A request can timeout and technically still succeed!
  # Consider the case when a
  # {http://developer.ebay.com/DevZone/XML/docs/Reference/ebay/AddFixedPriceItem.html AddFixedPriceItem}
  # call raises a +EbayTraderTimeoutError+. The item could have been successfully
  # uploaded, but a network issue delayed the response.
  # Hence, a +EbayTraderTimeoutError+ does not always imply the call failed.
  #
  class EbayTraderTimeoutError < EbayTraderError; end

  class << self

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield configuration
    end

    # Determine if the {https://github.com/RubyMoney/money Money} gem is installed.
    # @return [Boolean] +true+ if Money gem can be used by this app.
    #
    def is_money_gem_installed?
      begin
        return true if defined? Money
        gem 'money'
        require 'money' unless defined? Money
        true
      rescue Gem::LoadError
        false
      end
    end
  end
end
