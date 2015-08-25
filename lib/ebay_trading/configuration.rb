require 'digest'
require 'uri'

module EbayTrading
  class Configuration

    # URL for eBay's Trading API *Production* environment.
    # @see https://ebaydts.com/eBayKBDetails?KBid=429
    URI_PRODUCTION = 'https://api.ebay.com/ws/api.dll'

    # URL for eBay's Trading API *Sandbox* environment.
    # @see https://ebaydts.com/eBayKBDetails?KBid=429
    URI_SANDBOX = 'https://api.sandbox.ebay.com/ws/api.dll'

    # @return [String] Application keys Developer ID.
    attr_reader :dev_id

    # @return [String] Application keys App ID.
    attr_reader :app_id

    # @return [String] Application keys Certificate ID.
    attr_reader :cert_id

    # @return [URI] Get the URI for eBay API requests, which will be different for
    # sandbox and production environments.
    attr_reader :uri

    # @return [Fixnum] The default eBay site ID to use in API requests, default is 0.
    # This can be overridden by including an ebay_site_id value in the list of
    # arguments to {EbayTrading::Request#initialize}.
    # @see https://developer.ebay.com/DevZone/merchandising/docs/Concepts/SiteIDToGlobalID.html
    attr_accessor :ebay_site_id

    # @return [Fixnum] the eBay Trading API version.
    # @see http://developer.ebay.com/DevZone/XML/docs/ReleaseNotes.html
    attr_accessor :ebay_api_version

    # @return [Fixnum] the number of seconds before the HTTP session times out.
    attr_reader :http_timeout

    # @return [Symbol] :float, :fixnum or :money
    attr_reader :price_type

    # @return [Proc] an optional Proc or Lambda to record application level API request call volume.
    attr_reader :counter_callback

    def initialize
      self.environment = :sandbox
      @dev_id = nil
      @environment = :sandbox

      @dev_id  = nil
      @app_id  = nil
      @cert_id = nil

      @ebay_site_id = 0
      @ebay_api_version = 933   # 2015-Jul-24
      @http_timeout = 30        # seconds

      @price_type = :big_decimal

      @username_auth_tokens = {}
    end

    # Set the eBay environment to either *:sandbox* or *:production*.
    # If the value of +env+ is not recognized :sandbox will be assumed.
    # @param [Symbol] env :sandbox or :production
    # @return [Symbol] :sandbox or :production
    def environment=(env)
      @environment = (env.to_s.downcase.strip == 'production') ? :production : :sandbox
      @uri = URI.parse(production? ? URI_PRODUCTION : URI_SANDBOX)
      @environment
    end

    # Determine if this app is targeting eBay's production environment.
    # @return [Boolean] +true+ if production mode, otherwise +false+.
    def production?
      @environment == :production
    end

    # Determine if this app is targeting eBay's sandbox environment.
    # @return [Boolean] +true+ if sandbox mode, otherwise +false+.
    def sandbox?
      !production?
    end

    # Determine if all {#dev_id}, {#app_id} and {#cert_id} have all been set.
    # @return [Boolean] +true+ if dev_id, app_id and cert_id have been defined.
    def has_keys_set?
      !(dev_id.nil? || app_id.nil? || cert_id.nil?)
    end

    # Set the Dev ID application key.
    # @param [String] id the developer ID.
    def dev_id=(id)
      raise EbayTradingError, 'Dev ID does not appear to be valid' unless application_key_valid?(id)
      @dev_id = id
    end

    # Set the App ID application key.
    # @param [String] id the app ID.
    def app_id=(id)
      raise EbayTradingError, 'App ID does not appear to be valid' unless application_key_valid?(id)
      @app_id = id
    end

    # Set the Cert ID application key.
    # @param [String] id the certificate ID.
    def cert_id=(id)
      raise EbayTradingError, 'Cert ID does not appear to be valid' unless application_key_valid?(id)
      @cert_id = id
    end

    # Set the type to be used to represent price values, with the default being +:big_decimal+.
    # If performing calculations or analytics it be generally preferable to use integer
    # based values as it mitigates any rounding/accuracy issues.
    #
    # * +*:big_decimal*+ Price values will be parsed into
    # * +*:float*+ Price values will be parsed into floats.
    # * +*:fixnum*+ Price values will be converted to +Fixnum+
    # * +*:integer*+ Price values will be converted to +Fixnum+
    # * +*:money*+ Price values will be converted to {https://github.com/RubyMoney/money Money} objects, but only if the +Money+ gem is available to your app, otherwise +:fixnum+ will be assumed.
    #
    # @param [Symbol] price_type_symbol one of [:float, :fixnum, :integer, :money]
    # @return [Symbol] the symbol assumed for price values.
    #
    def price_type=(price_type_symbol)
      case price_type_symbol
        when :fixnum  then @price_type = :fixnum
        when :integer then @price_type = :fixnum
        when :float   then @price_type = :float
        when :money   then @price_type = EbayTrading.is_money_gem_installed? ? :money : :fixnum
        else
          @price_type = :big_decimal
      end
      @price_type
    end

    # This is an optional helper method to map eBay user IDs, or other acronyms,
    # to API auth tokens.
    # If mapped here the application can later retrieve an auth token
    # corresponding to an easy to remember string such as 'my_ebay_username'.
    #
    # @param [String]
    #

    # Map an eBay API auth token to an easy to remember +String+ key.
    # This could be the corresponding eBay username thus making it easier
    # to select the user auth token from a UI list or command line argument.
    #
    # @param [String] key auth_token identifier, typically an eBay username.
    # @param [String] auth_token an eBay API authentication token.
    #
    def store_auth_token(key, auth_token)
      @username_auth_tokens[secure_auth_token_key(key)] = auth_token
    end

    # Get the eBay API auth token matching the given +key+, or +nil+ if
    # not found.
    #
    # @return [String] the corresponding auth token, or nil.
    #
    def auth_token_for(key)
      @username_auth_tokens[secure_auth_token_key(key)]
    end

    # Provide a callback to track the number of eBay API calls made.
    #
    # As eBay rations the number of API calls you can make in a single day,
    # typically to 5_000, it is advisable to record the volume of calls submitted.
    # Here you can provide an application level callback that will be called
    # during each API {Request}.
    #
    # @param [Proc|lambda] callback to be called during each eBay API request call.
    #
    def counter=(callback)
      @counter_callback = callback if callback && callback.is_a?(Proc)
    end

    # Determine if a {#counter_callback} has been set for this application.
    #
    # @return [Boolean] +true+ if a counter proc or lambda has been provided.
    #
    def has_counter?
      @counter_callback != nil
    end

    #---------------------------------------------------------------------------
    private

    # Validate the given {#dev_id}, {#app_id} or {#cert_id}.
    # These are almost like GUID/UUID values with the exception that the first
    # block of 8 digits of AppID can be any letters.
    # @return [Boolean] +true+ if the ID has the correct format.
    #
    def application_key_valid?(id)
      id =~ /[A-Z0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}/i
    end

    def secure_auth_token_key(key)
      Digest::MD5.hexdigest(key.to_s.downcase)
    end

  end
end
