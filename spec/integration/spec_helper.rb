require "securerandom"

unless defined?(INTEGRATION_SPEC_HELPER_LOADED)
  INTEGRATION_SPEC_HELPER_LOADED = true
  SSL_TEST_PORT = ENV["SSL_TEST_PORT"] || 8444

  require File.dirname(__FILE__) + "/../spec_helper"

  def start_ssl_server
    web_server_pid_file = File.expand_path(File.join(File.dirname(__FILE__), "..", "httpsd.pid"))

    FileUtils.rm(web_server_pid_file) if File.exist?(web_server_pid_file)
    command = File.expand_path(File.join(File.dirname(__FILE__), "..", "script", "httpsd.rb"))
    `#{command} #{web_server_pid_file}`
    TCPSocket.new("127.0.0.1",SSL_TEST_PORT)

    10.times { unless File.exist?(web_server_pid_file); sleep 1; end }
  ensure
    Process.kill "INT", File.read(web_server_pid_file).to_i
  end

  def create_modification_for_tests(attributes)
    config = Braintree::Configuration.instantiate
    config.http.post("#{config.base_merchant_path}/modifications/create_modification_for_tests", :modification => attributes)
  end

  def with_other_merchant(merchant_id, public_key, private_key, &block)
    old_merchant_id = Braintree::Configuration.merchant_id
    old_public_key = Braintree::Configuration.public_key
    old_private_key = Braintree::Configuration.private_key

    Braintree::Configuration.merchant_id = merchant_id
    Braintree::Configuration.public_key = public_key
    Braintree::Configuration.private_key = private_key

    begin
      yield
    ensure
      Braintree::Configuration.merchant_id = old_merchant_id
      Braintree::Configuration.public_key = old_public_key
      Braintree::Configuration.private_key = old_private_key
    end
  end

  def with_advanced_fraud_kount_integration_merchant(&block)
    with_other_merchant("advanced_fraud_integration_merchant_id", "advanced_fraud_integration_public_key", "advanced_fraud_integration_private_key") do
      block.call
    end
  end

  def with_fraud_protection_enterprise_merchant(&block)
    with_other_merchant("fraud_protection_enterprise_integration_merchant_id", "fraud_protection_enterprise_integration_public_key", "fraud_protection_enterprise_integration_private_key") do
      block.call
    end
  end

  def with_chargeback_protection_merchant(&block)
    with_other_merchant("fraud_protection_effortless_chargeback_protection_merchant_id", "effortless_chargeback_protection_public_key", "effortless_chargeback_protection_private_key") do
      block.call
    end
  end

  def with_altpay_merchant(&block)
    with_other_merchant("altpay_merchant", "altpay_merchant_public_key", "altpay_merchant_private_key", &block)
  end

  def random_payment_method_token
    "payment-method-token-#{SecureRandom.hex(6)}"
  end

  def with_duplicate_checking_merchant(&block)
    with_other_merchant("dup_checking_integration_merchant_id", "dup_checking_integration_public_key", "dup_checking_integration_private_key") do
      block.call
    end
  end
end
