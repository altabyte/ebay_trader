require 'digest'
require 'uri'

module EbayTrader
  class Configuration

    # URL for eBay's Trading API *Production* environment.
    # @see https://ebaydts.com/eBayKBDetails?KBid=429
    URI_PRODUCTION = 'https://api.ebay.com/ws/api.dll'

    # URL for eBay's Trading API *Sandbox* environment.
    # @see https://ebaydts.com/eBayKBDetails?KBid=429
    URI_SANDBOX = 'https://api.sandbox.ebay.com/ws/api.dll'

    DEFAULT_AUTH_TOKEN_KEY = '__DEFAULT__'

    # The Dev ID application key.
    # @return [String] Application keys Developer ID.
    attr_accessor :dev_id

    # @return [String] Application keys App ID.
    attr_accessor :app_id

    # @return [String] Application keys Certificate ID.
    attr_accessor :cert_id

    # @return [URI] Get the URI for eBay API requests, which will be different for
    # sandbox and production environments.
    attr_accessor :uri

    # @return [Fixnum] The default eBay site ID to use in API requests, default is 0.
    # This can be overridden by including an ebay_site_id value in the list of
    # arguments to {EbayTrader::Request#initialize}.
    # @see https://developer.ebay.com/DevZone/merchandising/docs/Concepts/SiteIDToGlobalID.html
    attr_accessor :ebay_site_id

    # @return [Fixnum] the eBay Trading API version.
    # @see http://developer.ebay.com/DevZone/XML/docs/ReleaseNotes.html
    attr_accessor :ebay_api_version

    # @return [String] the eBay RuName for the application.
    # @see http://developer.ebay.com/DevZone/xml/docs/HowTo/Tokens/GettingTokens.html#step1
    attr_accessor :ru_name

    # @return [Fixnum] the number of seconds before the HTTP session times out.
    attr_reader :http_timeout

    # Set the type of object to be used to represent price values, with the default being +:big_decimal+.
    #
    # * +*:big_decimal*+ expose price values as +BigDecimal+
    # * +*:money*+ expose price values as {https://github.com/RubyMoney/money Money} objects, but only if the +Money+ gem is available to your app.
    # * +*:fixnum*+ expose price values as +Fixnum+
    # * +*:integer*+ expose price values as +Fixnum+
    # * +*:float*+ expose price values as +Float+ - not recommended!
    #
    # @return [Symbol] :big_decimal, :money, :fixnum or :float
    attr_accessor :price_type

    # @return [Proc] an optional Proc or Lambda to record application level API request call volume.
    attr_reader :counter_callback

    # Specify if the SSL certificate should be verified, +true+ by default.
    # It is recommended that all SSL certificates are verified to prevent
    # man-in-the-middle type attacks.
    #
    # One potential reason for temporarily deactivating verification is when
    # certificates expire, which they periodically do, and you need to take
    # emergency steps to keep your service running. In such cases you may
    # see the following error message:
    #
    #     SSL_connect returned=1 errno=0 state=SSLv3 read server certificate B: certificate verify failed
    #
    # @return [Boolean|String] +true+, +false+ or the path to {http://curl.haxx.se/ca/cacert.pem PEM certificate} file.
    #
    # @see http://www.rubyinside.com/how-to-cure-nethttps-risky-default-https-behavior-4010.html
    # @see http://www.rubyinside.com/nethttp-cheat-sheet-2940.html
    #
    attr_accessor :ssl_verify

    def initialize
      self.environment = :sandbox
      @dev_id = nil
      @environment = :sandbox

      @dev_id  = nil
      @app_id  = nil
      @cert_id = nil

      @ebay_site_id = 0
      @ebay_api_version = 935   # 2015-Jul-24
      @http_timeout = 30        # seconds

      @price_type = :big_decimal

      @username_auth_tokens = {}

      @ssl_verify = true
    end

    # Set the eBay environment to either *:sandbox* or *:production*.
    # If the value of +env+ is not recognized :sandbox will be assumed.
    #
    # @param [Symbol] env :sandbox or :production
    # @return [Symbol] :sandbox or :production
    #
    def environment=(env)
      @environment = (env.to_s.downcase.strip == 'production') ? :production : :sandbox
      @uri = URI.parse(production? ? URI_PRODUCTION : URI_SANDBOX)
      @environment
    end

    # Determine if this app is targeting eBay's production environment.
    # @return [Boolean] +true+ if production mode, otherwise +false+.
    #
    def production?
      @environment == :production
    end

    # Determine if this app is targeting eBay's sandbox environment.
    # @return [Boolean] +true+ if sandbox mode, otherwise +false+.
    #
    def sandbox?
      !production?
    end

    # Determine if all {#dev_id}, {#app_id} and {#cert_id} have all been set.
    # @return [Boolean] +true+ if dev_id, app_id and cert_id have been defined.
    #
    def has_keys_set?
      !(dev_id.nil? || app_id.nil? || cert_id.nil?)
    end

    # Optionally set a default authentication token to be used in API requests.
    #
    # @param [String] auth_token the eBay auth token for the user making requests.
    #
    def auth_token=(auth_token)
      map_auth_token(DEFAULT_AUTH_TOKEN_KEY, auth_token)
    end

    # Get the default authentication token, or +nil+ if not set.
    # @return [String] the default auth token.
    #
    def auth_token
      auth_token_for(DEFAULT_AUTH_TOKEN_KEY)
    end

    # Map an eBay API auth token to an easy to remember +String+ key.
    # This could be the corresponding eBay username thus making it easier
    # to select the user auth token from a UI list or command line argument.
    #
    # @param [String] key auth_token identifier, typically an eBay username.
    # @param [String] auth_token an eBay API authentication token.
    #
    def map_auth_token(key, auth_token)
      @username_auth_tokens[secure_auth_token_key(key)] = auth_token
    end

    # Get the eBay API auth token matching the given +key+, or +nil+ if
    # not found.
    #
    # @return [String] the corresponding auth token, or +nil+.
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
    # @return [Proc]
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

    def dev_id=(id)
      raise EbayTraderError, 'Dev ID does not appear to be valid' unless application_key_valid?(id)
      @dev_id = id
    end

    def app_id=(id)
      raise EbayTraderError, 'App ID does not appear to be valid' unless application_key_valid?(id)
      @app_id = id
    end

    def cert_id=(id)
      raise EbayTraderError, 'Cert ID does not appear to be valid' unless application_key_valid?(id)
      @cert_id = id
    end

    def price_type=(price_type_symbol)
      case price_type_symbol
        when :fixnum  then @price_type = :fixnum
        when :integer then @price_type = :fixnum
        when :float   then @price_type = :float
        when :money   then @price_type = EbayTrader.is_money_gem_installed? ? :money : :fixnum
        else
          @price_type = :big_decimal
      end
      @price_type
    end

    def ssl_verify=(verify)
      if verify
        @ssl_verify = verify.is_a?(String) ? verify : true
       else
        @ssl_verify = false
      end
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
