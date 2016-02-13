$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'ebay_trader'

# Add 'include FileToString' to spec files requiring this functionality.
module FileToString
  def file_to_string(file_path)
    string = File.open(file_path, 'r') { |f| f.read }
    return string
  end
end

def configure_api_production
  configure_api_environment :production
end

def configure_api_sandbox
  configure_api_environment :sandbox
end

#-----------------------------------------------------------------------------
private

def configure_api_environment(env)
  raise 'Environment must be either :production or :sandbox' unless [:production, :sandbox].include?(env)

  EbayTrader.configure do |config|

    config.ebay_api_version = 951

    config.environment      = env

    config.ebay_site_id     = 0 # ebay.com

    config.ssl_verify       = false

    config.auth_token = ENV['EBAY_API_AUTH_TOKEN_TEST_USER_1']

    config.dev_id  = (env == :production) ? ENV['EBAY_API_DEV_ID']  : ENV['EBAY_API_DEV_ID_SANDBOX']
    config.app_id  = (env == :production) ? ENV['EBAY_API_APP_ID']  : ENV['EBAY_API_APP_ID_SANDBOX']
    config.cert_id = (env == :production) ? ENV['EBAY_API_CERT_ID'] : ENV['EBAY_API_CERT_ID_SANDBOX']

    config.ru_name = ENV['EBAY_API_RU_NAME_01_SANDBOX']
  end
end
