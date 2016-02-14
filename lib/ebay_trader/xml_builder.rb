# frozen_string_literal: true

module EbayTrader
  class XMLBuilder

    attr_reader :context, :xml, :depth, :tab_width

    def initialize(args = {})
      @xml = ''
      @depth = 0
      @tab_width = (args[:tab_width] || 0).to_i
    end

    # Catch-all method to avoid having to create individual methods for each XML tag name.
    def method_missing(method_name, *args, &block)
      if @context && @context.respond_to?(method_name)
        @context.send(method_name, *args, &block)
      else
        node(method_name, args, &block)
      end
    end

    # Only respond to method names with only numbers and letters.
    # Do not respond to names with underscores.
    def respond_to_missing?(method_name, include_private = false)
      super || method_name.to_s =~ /^[a-z0-9]+$/i
    end

    # Begin creating an XML string by specifying the root node.
    # This also sets the context scope, allowing methods and variables
    # outside the block to be accessed.
    # @param [String] name the name of the root node element.
    # @param [Array]  args the data for this element.
    # @param [Block]  block an optional block of sub-elements to be nested
    #                 within the root node.
    def root(name, *args, &block)
      set_context(&block)
      node(name, args, &block)
    end

    #---------------------------------------------------------------------------
    private

    # @see https://github.com/sparklemotion/nokogiri/blob/master/lib/nokogiri/xml/builder.rb
    def set_context(&block)
      @context = block_given? ? eval('self', block.binding) : nil
      @context = nil if @context.is_a?(XMLBuilder)
    end

    # Create an XML node
    # @param [String|Symbol] name the name of the XML element (ul, li, strong, etc...)
    # @param [Array] args Can contain a String of text or a Hash of attributes
    # @param [Block] block An optional block which will further nest XML
    def node(name, args, &block)
      content = get_node_content(args)
      options = format_node_attributes(get_node_attributes(args))

      @_segments ||= []
      @_segments << "#{indent_new_line}<#{name}#{options}>#{content}"
      if block_given?
        @depth += 1
        instance_eval(&block)
        @depth -= 1
        @_segments << indent_new_line
      end
      @_segments << "</#{name}>"
      @xml = @_segments.join('').strip
    end

    # Return the first Hash in the list of arguments to #node
    # as this defines the attributes for the XML node.
    # @return [Hash] the hash of attributes for this node.
    #
    def get_node_attributes(args)
      args.detect { |arg| arg.is_a? Hash } || {}
    end

    # Return the node content as a String, unless a block is given.
    # @return [String] the node data.
    #
    def get_node_content(args)
      return nil if block_given?
      content = nil
      args.each do |arg|
        case arg
          when Hash
            next
          when Time
            # eBay official TimeStamp format YYYY-MM-DDTHH:MM:SS.SSSZ
            content = arg.strftime('%Y-%m-%dT%H:%M:%S.%Z')
          when DateTime
            content = arg.strftime('%Y-%m-%dT%H:%M:%S.%Z')
            break
          else
            content = arg.to_s
            break
        end
      end
      content
    end

    # Convert the given Hash of options into a string of XML element attributes.
    #
    def format_node_attributes(options)
      options.collect { |key, value|
        value = value.to_s.gsub('"', '\"')
        " #{key}=\"#{value}\""
      }.join('')
    end

    # Add a new line to the XML and indent with the appropriate number of spaces.
    def indent_new_line
      tab_width > 0 ? ("\n" + (' ' * tab_width * depth)) : ''
    end
  end
end
