# frozen_string_literal: true

require 'active_support/gzip'
require 'net/http'
require 'ox'
require 'rexml/document'
require 'securerandom'
require 'yaml'
require 'openssl'
require 'base64'

require 'ebay_trader'
require 'ebay_trader/sax_handler'
require 'ebay_trader/xml_builder'

module EbayTrader

  class Request

    # A Struct wrapper around eBay generated error and warning messages.
    Error = Struct.new(:error_classification, :severity_code, :error_code, :short_message, :long_message) do
      def error?;   severity_code == 'Error';   end
      def warning?; severity_code == 'Warning'; end
    end

    # eBay Trading API XML Namespace
    XMLNS = 'urn:ebay:apis:eBLBaseComponents'

    attr_reader :call_name
    attr_reader :auth_token
    attr_reader :ebay_site_id
    attr_reader :message_id
    attr_reader :response_hash
    attr_reader :skip_type_casting
    attr_reader :known_arrays
    attr_reader :xml_tab_width
    attr_reader :xml_request
    attr_reader :xml_response
    attr_reader :http_timeout
    attr_reader :http_response_code
    attr_reader :response_time

    # Construct a new eBay Trading API call.
    #
    # @param [String] call_name the name of the API call, for example 'GeteBayOfficialTime'.
    #
    # @param [Hash] args optional configuration values for this request.
    #
    # @option args [String] :auth_token the eBay Auth Token for the user submitting this request.
    #                       If not defined the value of {Configuration#auth_token} will be assumed.
    #
    # @option args [Fixnum] :ebay_site_id Override the default eBay site ID in {Configuration#ebay_site_id}
    #
    # @option args [Fixnum] :http_timeout Override the default value of {Configuration#http_timeout}.
    #
    #                       This may be necessary for one-off calls such as
    #                       {http://developer.ebay.com/DevZone/XML/docs/Reference/ebay/UploadSiteHostedPictures.html UploadSiteHostedPictures}
    #                       which can take significantly longer.
    #
    # @option args [Array [String]] :skip_type_casting An array of the keys for which the values should *not*
    #                       get automatically type cast.
    #
    #                       Take for example the 'BuyerUserID' field. If someone has the username '123456'
    #                       the auto-type-casting would consider this to be a Fixnum. Adding 'BuyerUserID'
    #                       to skip_type_casting list will ensure it remains a String.
    #
    # @option args [Array [String]] :known_arrays a list of the names of elements that are known to have arrays
    #                       of values. If defined here {#response_hash} will ensure array values in circumstances
    #                       where there is only a single child element in the response XML.
    #
    #                       It is not necessary to use this feature, but doing so can simplify later stage logic
    #                       as certain fields are guaranteed to be arrays. As there is no concept of arrays in XML
    #                       it is not otherwise possible to determine if a field should be an array.
    #
    #                       An example case is when building a tree of nested categories. Some categories may only have
    #                       one child category, but adding 'Category' or :category to this list will ensure the
    #                       response_hash values is always an array. Hence it will not necessary to check if the elements
    #                       of a category element is a Hash or an Array of Hashes when recursing through the data.
    #
    # @option args [String] :xml_response inject a pre-prepared XML response.
    #
    #                       If an XML response is given here the request will not actually be sent to eBay.
    #                       Using this feature can dramatically speed up testing and also ensure you stay
    #                       within eBay's 5,000 requests per day throttling rate.
    #
    #                       It is also a useful feature for parsing locally cached/archived XML files.
    #
    # @option args [Fixnum] :xml_tab_width the number of spaces to indent child elements in the generated XML.
    #                       The default is 0, meaning the XML is a single line string, but it's
    #                       nice to have the option of pretty-printing the XML for debugging.
    #
    # @yield [xml_builder] a block describing the XML DOM.
    #
    # @yieldparam name [XMLBuilder] an XML builder node allowing customization of the request specific details.
    #
    # @yieldreturn [XMLBuilder] the same XML builder originally provided by the block.
    #
    # @raise [EbayTraderError] if the API call fails.
    #
    # @raise [EbayTraderTimeoutError] if the HTTP call times out.
    #
    def initialize(call_name, args = {}, &block)
      time = Time.now
      @call_name  = call_name.freeze

      auth_token = %w"GetSessionID FetchToken".include?(call_name) ?
                      nil : (args[:auth_token] || EbayTrader.configuration.auth_token)
      @auth_token = auth_token.freeze

      @ebay_site_id = (args[:ebay_site_id] || EbayTrader.configuration.ebay_site_id).to_i
      @http_timeout = (args[:http_timeout] || EbayTrader.configuration.http_timeout).to_f
      @xml_tab_width = (args[:xml_tab_width] || 0).to_i

      @xml_response = args[:xml_response] || ''

      @skip_type_casting = args[:skip_type_casting] || []
      @skip_type_casting = @skip_type_casting.split if @skip_type_casting.is_a?(String)

      @known_arrays = args[:known_arrays] || []
      @known_arrays = @known_arrays.split if @known_arrays.is_a?(String)
      @known_arrays << 'errors'

      @message_id = nil
      if args.key?(:message_id)
        @message_id = (args[:message_id] == true) ? SecureRandom.uuid : args[:message_id].to_s
      end

      doc = XMLBuilder.new(tab_width: xml_tab_width).root("#{call_name}Request", xmlns: XMLNS) do
        unless auth_token.blank?
          RequesterCredentials do
            eBayAuthToken auth_token.to_s
          end
        end
        instance_eval(&block) if block_given?
        MessageID message_id unless message_id.nil?
      end
      @xml_request = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n#{doc}"

      @http_response_code = 200
      submit if xml_response.blank?

      parsed_hash = parse(xml_response)
      root_key = parsed_hash.keys.first
      raise EbayTraderError, "Response '#{root_key}' does not match call name" unless root_key.gsub('_', '').eql?("#{call_name}Response".downcase)

      @response_hash = parsed_hash[root_key]
      @response_hash.freeze
      @response_time = Time.now - time

      @errors = []
      deep_find(:errors, []).each do |error|
        @errors << Error.new(error[:error_classification],
                             error[:severity_code],
                             error[:error_code],
                             error[:short_message],
                             error[:long_message])
      end
    end

    # Determine if this request has been successful.
    # This should return the opposite of {#failure?}
    def success?
      deep_find(:ack, '').downcase.eql?('success')
    end

    # Determine if this request has failed.
    # This should return the opposite of {#success?}
    def failure?
      deep_find(:ack, '').downcase.eql?('failure')
    end

    # Determine if this response has partially failed.
    # This eBay response is somewhat ambiguous, but generally means the request was
    # processed by eBay, but warnings were generated.
    def partial_failure?
      deep_find(:ack, '').downcase.eql?('partialfailure')
    end

    # Determine if this request has generated any {#errors} or {#warnings}.
    # @return [Boolean] +true+ if errors or warnings present.
    def has_errors_or_warnings?
      has_errors? || has_warnings?
    end

    # Get an array of all {#errors} and {#warnings}.
    # @return [Array[Error]] all {#errors} and {#warnings} combined.
    def errors_and_warnings
      @errors
    end

    # Determine if this request has generated any {#errors}, excluding {#warnings}.
    # @return [Boolean] +true+ if any errors present.
    def has_errors?
      errors.count > 0
    end

    # Get an array of {Error}s, excluding {#warnings}. This will be an empty array if there are no errors.
    # @return [Array[Error]] which have a severity_code of 'Error'.
    def errors
      @errors.select { |error| error.error? }
    end

    # Determine if this request has generated any {#warnings}.
    # @return [Boolean] +true+ if warnings present.
    def has_warnings?
      warnings.count > 0
    end

    # Get an array of {Error}s representing warnings. This will be an empty array if there are no errors.
    # @return [Array[Error]] which have a severity_code of 'Warning'.
    def warnings
      @errors.select { |error| error.warning? }
    end

    # Get the timestamp of the response returned by eBay API.
    # The timestamp indicates the time when eBay processed the request; it does
    # not necessarily indicate the current eBay official eBay time.
    # In particular, calls like
    # {http://developer.ebay.com/DevZone/XML/docs/Reference/eBay/GetCategories.html GetCategories}
    # can return a cached response, so the time stamp may not be current.
    # @return [Time] the response timestamp.
    #
    def timestamp
      deep_find :timestamp
    end

    # Recursively deep search through the {#response_hash} tree and return the
    # first value matching the given +path+ of node names.
    # If +path+ cannot be matched the value of +default+ is returned.
    # @param [Array [String|Symbol]] path an array of the keys defining the path to the node of interest.
    # @param [Object] default the value to be returned if +path+ cannot be matched.
    # @return [Array] the first value found in +path+, or +default+.
    def deep_find(path, default = nil)
      @response_hash.deep_find(path, default)
    end

    # Get a String representation of the response XML with indentation.
    # @return [String] the response XML.
    def to_s(indent = xml_tab_width)
      xml = ''
      if defined? Ox
        ox_doc = Ox.parse(xml_response)
        xml = Ox.dump(ox_doc, indent: indent)
      else
        rexml_doc = REXML::Document.new(xml_response)
        rexml_doc.write(xml, indent)
      end
      xml
    end

    # Get a String representation of the XML data hash in JSON notation.
    # @return [String] pretty printed JSON.
    def to_json_s
      require 'json' unless defined? JSON
      puts JSON.pretty_generate(JSON.parse(@response_hash.to_json))
    end

    #-------------------------------------------------------------------------
    private

    # Post the xml_request to eBay and record the xml_response.
    def submit
      raise EbayTraderError, 'Cannot post an eBay API request before application keys have been set' unless EbayTrader.configuration.has_keys_set?

      uri = EbayTrader.configuration.uri

      http = Net::HTTP.new(uri.host, uri.port)
      http.read_timeout = http_timeout

      if uri.port == 443
        # http://www.rubyinside.com/nethttp-cheat-sheet-2940.html
        http.use_ssl = true
        verify = EbayTrader.configuration.ssl_verify
        if verify
          if verify.is_a?(String)
            pem = File.read(verify)
            http.cert = OpenSSL::X509::Certificate.new(pem)
            http.key = OpenSSL::PKey::RSA.new(pem)
          end
          http.verify_mode = OpenSSL::SSL::VERIFY_PEER
        else
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end

      end

      post = Net::HTTP::Post.new(uri.path, headers)
      post.body = xml_request

      begin
        response = http.start { |http| http.request(post) }
      rescue OpenSSL::SSL::SSLError => e
        # SSL_connect returned=1 errno=0 state=SSLv3 read server certificate B: certificate verify failed
        raise EbayTraderError, e
      rescue Net::ReadTimeout
        raise EbayTraderTimeoutError, "Failed to complete #{call_name} in #{http_timeout} seconds"
      rescue Exception => e
        raise EbayTraderError, e
      ensure
        EbayTrader.configuration.counter_callback.call if EbayTrader.configuration.has_counter?
      end

      @http_response_code = response.code.to_i.freeze

      # If the call was successful it should have a response code starting with '2'
      # http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html
      raise EbayTraderError, "HTTP Response Code: #{http_response_code}" unless http_response_code.between?(200, 299)

      if response['Content-Encoding'] == 'gzip'
        @xml_response = ActiveSupport::Gzip.decompress(response.body)
      else
        @xml_response = response.body
      end
    end

    # Parse the given XML using {SaxHandler} and return a nested Hash.
    # @param [String] xml the XML string to be parsed.
    # @return [Hash] a Hash corresponding to +xml+.
    def parse(xml)
      xml ||= ''
      xml = StringIO.new(xml) unless xml.respond_to?(:read)

      handler = SaxHandler.new(skip_type_casting: skip_type_casting, known_arrays: known_arrays)
      Ox.sax_parse(handler, xml, convert_special: true)
      handler.to_hash
    end

    #
    # Get a hash of the default headers to be submitted to eBay API via httparty.
    # Additional headers can be merged into this hash as follows:
    # ebay_headers.merge({'X-EBAY-API-CALL-NAME' => 'CallName'})
    # http://developer.ebay.com/Devzone/XML/docs/WebHelp/InvokingWebServices-Routing_the_Request_(Gateway_URLs).html
    #
    def headers
      headers = {
          'X-EBAY-API-COMPATIBILITY-LEVEL' => "#{EbayTrader.configuration.ebay_api_version}",
          'X-EBAY-API-SITEID' => "#{ebay_site_id}",
          'X-EBAY-API-CALL-NAME' => call_name,
          'Content-Type' => 'text/xml',
          'Accept-Encoding' => 'gzip'
      }
      xml = xml_request
      headers.merge!({'Content-Length' => "#{xml.length}"}) if xml && !xml.strip.empty?

      # These values are only required for calls that set up and retrieve a user's authentication token
      # (these calls are: GetSessionID, FetchToken, GetTokenStatus, and RevokeToken).
      # In all other calls, these value are ignored..
      if %w"GetSessionID FetchToken GetTokenStatus RevokeToken".include?(call_name)
        headers.merge!({'X-EBAY-API-DEV-NAME'  => EbayTrader.configuration.dev_id})
        headers.merge!({'X-EBAY-API-APP-NAME'  => EbayTrader.configuration.app_id})
        headers.merge!({'X-EBAY-API-CERT-NAME' => EbayTrader.configuration.cert_id})
      end
      headers
    end
  end
end
