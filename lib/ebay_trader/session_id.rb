# frozen_string_literal: true

require 'cgi'
require 'ebay_trader/request'

module EbayTrader

  # Request a session ID from the eBay API.
  #
  # @see http://developer.ebay.com/DevZone/XML/docs/Reference/eBay/GetSessionID.html
  # @see http://developer.ebay.com/DevZone/XML/docs/HowTo/Tokens/GettingTokens.html
  # @see http://developer.ebay.com/DevZone/guides/ebayfeatures/Basics/Tokens-MultipleUsers.html
  #
  class SessionID < Request

    CALL_NAME = 'GetSessionID'

    # The application RuName defined in {Configuration#ru_name}, unless over-ridden in {#initialize} args.
    # @return [String] the RuName for this call.
    # @see https://developer.ebay.com/DevZone/account/appsettings/Consent/
    #
    attr_reader :ru_name

    # Construct a GetSessionID eBay API call.
    # @param [Hash] args a hash of optional arguments.
    # @option args [String] :ru_name Override the default RuName,
    #                       which should be defined in {Configuration#ru_name}.
    #
    def initialize(args = {})
      @ru_name = (args[:ru_name] || EbayTrader.configuration.ru_name).freeze

      super(CALL_NAME, args) do
        RuName ru_name
      end
    end

    # Get the session ID returned by the API call.
    # @return [String] the session ID.
    #
    def id
      response_hash[:session_id]
    end

    # Get the URL through which a user must sign in using this session ID.
    # @param [Hash] ruparams eBay appends this data to the AcceptURL and RejectURL.
    #               In a typical rails app this might include the user's model primary key.
    # @return [String] the sign-in URL.
    #
    def sign_in_url(ruparams = {})
      url = []
      url << EbayTrader.configuration.production? ? 'https://signin.ebay.com' : 'https://signin.sandbox.ebay.com'
      url << '/ws/eBayISAPI.dll?SignIn'
      url << "&runame=#{url_encode ru_name}"
      url << "&SessID=#{url_encode id}"
      if ruparams && ruparams.is_a?(Hash) && !ruparams.empty?
        params = []
        ruparams.each_pair { |key, value| params << "#{key}=#{value}" }
        url << "&ruparams=#{url_encode(params.join('&'))}"
      end
      url.join
    end

    #---------------------------------------------------------------
    private

    def url_encode(string)
      CGI.escape string
    end

    def url_decode(string)
      CGI.unescape string
    end
  end
end
