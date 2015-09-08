# EbayTrader

**EbayTrader** is a lightweight easy to use Ruby gem for interacting with [eBay's Trading API](http://developer.ebay.com/DevZone/XML/docs/Reference/eBay/index.html).
Leveraging Ruby's missing_method meta-programming DSL techniques, EbayTrader allows you to quickly and intuitively post XML requests
to eBay and parses the response. The response data is available in the form of a Hash, actually a 
[HashWithIndifferentAccess](http://api.rubyonrails.org/classes/ActiveSupport/HashWithIndifferentAccess.html) so keys `:key_name` and `"key_name"` are treated equally,
and values are auto-type-cast to String, Fixnum, Float, Boolean, BigDecimal or [Money](https://github.com/RubyMoney/money).

## Simple example

Let's start with a simple example. Here we will request a list of [categories](http://www.ebay.com/sch/allcategories/all-categories)
from eBay via a [GetCategories](http://developer.ebay.com/DevZone/XML/docs/Reference/eBay/GetCategories.html) API call.
Assuming there are no errors or warnings a list of all eBay category names will be printed.

```ruby
require 'ebay_trader'
require 'ebay_trader/request'

EbayTrader.configure do |config|
  # Configuration is described in the section below...
end

request = EbayTrader::Request.new('GetCategories') do
  CategorySiteID 0
  CategoryParent ARGV.first unless ARGV.empty?
  DetailLevel 'ReturnAll'
  LevelLimit 5
  ViewAllNodes true
end
request.errors_and_warnings.each { |error| puts error.long_message } if request.has_errors_or_warnings?

if request.success?
  category_names = request.response_hash[:category_array][:category].map { |c| c[:category_name] }
  category_names.each { |name| puts name }
end
```

Notice that in the above example if `ARGV` is an empty array `CategoryParent` node will be excluded from the XML document.

### CamelCase method names?!

Before you start screaming that this goes against the conventions of the [Ruby style guide](https://github.com/bbatsov/ruby-style-guide),
let me justify it by reminding you that the [eBay XML schema](http://developer.ebay.com/webservices/latest/ebaySvc.xsd) 
uses **CamelCase**. It is thus rather counter productive to copy an paste key names from eBay's documentation, 
manually adapt them to **snake_case** for the sake of etiquette, then write a method to convert these snake_case 
key names back into CamelCase.

## Nested data example

As shown above the `EbayTrader::Request` constructor accepts a block with a DSL describing the structure of the XML 
document to be posted to the eBay Trading API. Additional hierarchy in the XML can be described by nesting more blocks
within this DSL. The following example show a call to [GetMyeBaySelling](http://developer.ebay.com/DevZone/XML/docs/Reference/ebay/GetMyeBaySelling.html)
to retrieve a list of **unsold** items.

```ruby
duration =  30 # days
per_page = 100
page_number = 2

request = EbayTrader::Request.new('GetMyeBaySelling') do
  ErrorLanguage 'en_GB'
  WarningLevel 'High'
  DetailLevel 'ReturnAll'

  UnsoldList do
    Include 'true'
    DurationInDays duration  # 0..60
    Pagination do
      EntriesPerPage per_page
      PageNumber page_number
    end
  end

  ActiveList do 
    Include false
  end
  
  BidList do 
    Include false
  end
           
  DeletedFromSoldList do 
    Include false
  end
                       
  DeletedFromUnsoldList do 
    Include false
  end
                         
  ScheduledList do 
    Include false
  end
                 
  SoldList do 
    Include false
  end
end
```

For a list of more comprehensive examples please feel free to check out my [ebay_trader_support](https://github.com/altabyte/ebay_trader_support)
gem. This gem hosts some of the classes and command line tools from my production environment.

### Response data

The data tree returned by eBay is accessible through `request.response_hash`. Response hash is a [HashWithIndifferentAccess](http://api.rubyonrails.org/classes/ActiveSupport/HashWithIndifferentAccess.html)
which has been monkey patched to include a `deep_find` method. This `deep_find` method expects an array of key names and
performs a depth-first search on response_hash, returning the *first* value matching the path.

If for example I made a [GetItem](http://developer.ebay.com/DevZone/XML/docs/Reference/ebay/GetItem.html) API call I could
determine the [current price](http://developer.ebay.com/DevZone/XML/docs/Reference/ebay/GetItem.html#Response.Item.SellingStatus.CurrentPrice) as follows:

```ruby
request.response_hash.deep_find([:item, :selling_status, :current_price])
```

If any of the nodes in the path are absent a value of `nil` will be returned. 
`deep_find` can be instructed return a default should there be no value at the specified path. 
In the following example $0.00 USD will be returned instead of `nil` if there is no value at
`response_hash[:item][:selling_status][:current_price]` or the path does not exist.

```ruby
request.response_hash.deep_find([:item, :selling_status, :current_price], Money.new(0_00, 'USD'))
```

## Configuration

Before using this gem you must configure it with your [eBay Developer](https://go.developer.ebay.com/) credentials. 
Shown below is an example configuration.

```ruby
EbayTrader.configure do |config|

  config.ebay_api_version = 935

  # Environment can be :sandbox or :production
  config.environment = :sandbox

  # Optional as ebay_site_id can also be specified for each request.
  # 0 for ebay.com [Default]
  # 3 for ebay.co.uk
  config.ebay_site_id = 0

  # If you are getting error messages regarding SSL Certificates
  # you can [temporarily] disable SSL verification.
  # Caution! setting this to false will make you vulnerable to man-in-the-middle attacks.
  # The default value is true
  config.ssl_verify = false  # because I like to live dangerously

  # Optional as auth_token can also be specified for each request.
  config.auth_token = ENV['EBAY_API_AUTH_TOKEN']

  config.dev_id  = ENV['EBAY_API_DEV_ID']
  config.app_id  = ENV['EBAY_API_APP_ID']
  config.cert_id = ENV['EBAY_API_CERT_ID']

  config.ru_name = ENV['EBAY_API_RU_NAME']
  
  # By default price values are represented as BigDecimal
  # This can be changed to any of the following
  #   :big_decimal, :fixnum, :integer, :float or :money
  # :money can only be specified if the Money gem is available to your application.
  config.price_type = :big_decimal
end
```

The latest eBay API version number can be found in the [Trading API Release Notes](http://developer.ebay.com/DevZone/XML/docs/ReleaseNotes.html).

### Counting calls

As eBay [limits the number](https://go.developer.ebay.com/api-call-limits) of API calls 
that can be made each day, you may wish to keep track of your usage. You can provide an optional counter callback
that will be called during each post.

Here is an example of how to use a [Redis](http://redis.io/) database to keep track of daily API calls.

```ruby
config.counter = lambda {
    begin
      redis = Redis.new(host: 'localhost')
      key = "ebay_trader:production:call_count:#{Time.now.utc.strftime('%Y-%m-%d')}"
      redis.incr(key)
    rescue SocketError
      puts 'Failed to increment Redis call counter!'
    end
  }
```


## Customizing request calls

`EbayTrader::Request.new` method accepts a Hash of options. Listed below are some of the common options.
  
### Authentication token and site ID

An `:auth_token` and/or `:ebay_site_id` can be passed to each request, overriding any
value defined in the module configuration.

```ruby
request = EbayTrader::Request.new('GetItem', auth_token: ENV[EBAY_AUTH_TOKEN], ebay_site_id: 3) do
  CategorySpecific {
    CategoryID category_id_number
  }
end
```

### Extending timeout

By default each request will allow up to 30 seconds (although this can be changed in the module 
configuration) before raising a timeout error. However some calls such as [UploadSiteHostedPictures](http://developer.ebay.com/DevZone/XML/docs/Reference/eBay/UploadSiteHostedPictures.html)
may require more time, especially if uploading large images. 
This timeout can be extended with the following option `http_timeout: 60`

### Automatic type-casting

By default this gem tries to guess and auto-cast values to their appropriate types. As this is based on simple pattern
recognition it does not always get it right. Take for example a call to [GetUser](http://developer.ebay.com/DevZone/XML/docs/Reference/ebay/GetUser.html).
If an eBay user has the username ID '123456' this gem will type-cast the value to a `Fixnum`. This can be prevented by passing 
an array of keys to be excluded from type-casting to the `Request` constructor. 

```ruby
SKIP_TYPE_CASTING = [
        :charity_id,
        :city_name,
        :international_street,
        :phone,
        :postal_code,
        :name,
        :skype_id,
        :street,
        :street1,
        :street2,
        :user_id,
        :vat_id
    ]
    
request = EbayTrader::Request.new('GetUser', skip_type_casting: SKIP_TYPE_CASTING) do
  UserID user_id unless user_id.nil?
  ItemID item_id.to_s unless item_id.nil?
end
```

### Known arrays

One of the limitations of XML is that it is not possible to explicitly define arrays. This means that when a response
contains a list with only one element a parser cannot intrinsically determine that it should be an array. 
To overcome this limitation you can provide a list of known arrays to the request.

```ruby
KNOWN_ARRAYS = [
        :compatibility,
        :copyright,
        :cross_border_trade,
        :discount_profile,
        :ebay_picture_url,
        :exclude_ship_to_location,
        :external_picture_url,
        :gift_services,
        :international_shipping_service_option,
        :item_specifics,
        :listing_enhancement,
        :name_value_list,
        :payment_allowed_site,
        :payment_methods,
        :promoted_item,
        :picture_url,
        :shipping_service_options,
        :ship_to_location,
        :ship_to_locations,
        :skype_contact_option,
        :tax_jurisdiction,
        :value,
        :variation,
        :variation_specific_picture_set,
        :variation_specifics,
        :variation_specifics_set
    ]
    
request = EbayTrader::Request.new('GetItem', known_arrays: KNOWN_ARRAYS) do
  ItemID item_id
  IncludeWatchCount true
  IncludeItemSpecifics true
  DetailLevel 'ItemReturnDescription' if include_description?
end  
```

Subsequently you can simply iterate over the data without having to first check if it is an array. This can also eliminate
a post-processing step should you wish to dump the response hashes into [mongoDB](https://www.mongodb.org/) for analysis.

### Cached responses

For testing and debugging you can inject a String containing the expected eBay response XML 
with the `xml_response: xml_string` option. If given this string will be parsed and no data will be posted
to the eBay API.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ebay_trader'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ebay_trader

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/altabyte/ebay_trading.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

