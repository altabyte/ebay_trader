#!/usr/bin/env ruby

#
# This example downloads the list of categories from eBay and prints out their names.
#
# With no arguments this script will display all category names.
# To get a list of sub-categories provide a parent category ID as the first argument.
#

require 'ebay_trader'
require 'ebay_trader/request'

EbayTrader.configure do |config|

  config.ebay_api_version = 935
  config.environment      = :sandbox
  config.ebay_site_id     = 0 # ebay.com

  config.auth_token = ENV['EBAY_API_AUTH_TOKEN_TEST_USER_1']

  config.dev_id  = ENV['EBAY_API_DEV_ID_SANDBOX']
  config.app_id  = ENV['EBAY_API_APP_ID_SANDBOX']
  config.cert_id = ENV['EBAY_API_CERT_ID_SANDBOX']
  config.ru_name = ENV['EBAY_API_RU_NAME_01_SANDBOX']
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
