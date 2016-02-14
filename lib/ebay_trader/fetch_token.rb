# frozen_string_literal: true

require 'active_support/time'
require 'ebay_trader/request'
require 'ebay_trader/session_id'

module EbayTrader

  # Fetch an eBay user authentication token using a {SessionID} value.
  #
  # @see http://developer.ebay.com/DevZone/XML/docs/Reference/eBay/FetchToken.html
  # @see http://developer.ebay.com/DevZone/XML/docs/HowTo/Tokens/GettingTokens.html
  # @see http://developer.ebay.com/DevZone/guides/ebayfeatures/Basics/Tokens-MultipleUsers.html
  #
  class FetchToken < Request

    CALL_NAME = 'FetchToken'

    attr_reader :session_id

    # Construct a fetch token eBay API request with the given session ID.
    # @param [SessionID|String] session_id the session ID.
    # @param [Hash] args a hash of optional arguments.
    #
    def initialize(session_id, args = {})
      session_id = session_id.id if session_id.is_a?(SessionID)
      @session_id = session_id.freeze
      super(CALL_NAME, args) do
        SessionID session_id
      end
    end

    # Get the authentication token.
    # @return [String] the authentication token.
    #
    def auth_token
      response_hash[:ebay_auth_token]
    end

    # Get the Time at which the authentication token expires.
    # @return [Time] the expiry time.
    #
    def expiry_time
      response_hash[:hard_expiration_time]
    end
  end
end
