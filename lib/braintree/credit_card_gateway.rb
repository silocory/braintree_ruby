module Braintree
  class CreditCardGateway
    include BaseModule

    def initialize(gateway)
      @gateway = gateway
      @config = gateway.config
      @config.assert_has_access_token_or_keys
    end

    def create(attributes)
      if attributes.has_key?(:expiration_date) && (attributes.has_key?(:expiration_month) || attributes.has_key?(:expiration_year))
        raise ArgumentError.new("create with both expiration_month and expiration_year or only expiration_date")
      end
      # NEXT_MAJOR_VERSION remove this check
      if attributes.has_key?(:venmo_sdk_payment_method_code) || attributes.has_key?(:venmo_sdk_session)
        warn "[DEPRECATED] The Venmo SDK integration is Unsupported. Please update your integration to use Pay with Venmo instead."
      end
      Util.verify_keys(CreditCardGateway._create_signature, attributes)
      _do_create("/payment_methods", :credit_card => attributes)
    end

    def create!(*args)
      return_object_or_raise(:credit_card) { create(*args) }
    end

    # NEXT_MAJOR_VERSION remove this method
    # CreditCard.credit has been deprecated in favor of Transaction.credit
    def credit(token, transaction_attributes)
      warn "[DEPRECATED] CreditCard.credit is deprecated. Use Transaction.credit instead"
      @gateway.transaction.credit(transaction_attributes.merge(:payment_method_token => token))
    end

     # NEXT_MAJOR_VERSION remove this method
     # CreditCard.credit has been deprecated in favor of Transaction.credit
    def credit!(*args)
      warn "[DEPRECATED] CreditCard.credit is deprecated. Use Transaction.credit instead"
      return_object_or_raise(:transaction) { credit(*args) }
    end

    def delete(token)
      @config.http.delete("#{@config.base_merchant_path}/payment_methods/credit_card/#{token}")
    end

    def expired(options = {})
      response = @config.http.post("#{@config.base_merchant_path}/payment_methods/all/expired_ids")
      ResourceCollection.new(response) { |ids| _fetch_expired(ids) }
    end

    def expiring_between(start_date, end_date, options = {})
      formatted_start_date = start_date.strftime("%m%Y")
      formatted_end_date = end_date.strftime("%m%Y")
      response = @config.http.post("#{@config.base_merchant_path}/payment_methods/all/expiring_ids?start=#{formatted_start_date}&end=#{formatted_end_date}")
      ResourceCollection.new(response) { |ids| _fetch_expiring_between(formatted_start_date, formatted_end_date, ids) }
    end

    def find(token)
      raise ArgumentError if token.nil? || token.to_s.strip == ""
      response = @config.http.get("#{@config.base_merchant_path}/payment_methods/credit_card/#{token}")
      CreditCard._new(@gateway, response[:credit_card])
    rescue NotFoundError
      raise NotFoundError, "payment method with token #{token.inspect} not found"
    end

    def from_nonce(nonce)
      raise ArgumentError if nonce.nil? || nonce.to_s.strip == ""
      response = @config.http.get("#{@config.base_merchant_path}/payment_methods/from_nonce/#{nonce}")
      CreditCard._new(@gateway, response[:credit_card])
    rescue NotFoundError
      raise NotFoundError, "nonce #{nonce.inspect} locked, consumed, or not found"
    end

    def update(token, attributes)
      # NEXT_MAJOR_VERSION remove this check
      if attributes.has_key?(:venmo_sdk_payment_method_code) || attributes.has_key?(:venmo_sdk_session)
        warn "[DEPRECATED] The Venmo SDK integration is Unsupported. Please update your integration to use Pay with Venmo instead."
      end
      Util.verify_keys(CreditCardGateway._update_signature, attributes)
      _do_update(:put, "/payment_methods/credit_card/#{token}", :credit_card => attributes)
    end

    def update!(*args)
      return_object_or_raise(:credit_card) { update(*args) }
    end

    def self._create_signature
      _signature(:create)
    end

    def self._update_signature
      _signature(:update)
    end

    def self._signature(type)
      billing_address_params = AddressGateway._shared_signature
      # NEXT_MAJOR_VERSION Remove venmo_sdk_session
      # The old venmo SDK class has been deprecated
      options = [
        :fail_on_duplicate_payment_method,
        :fail_on_duplicate_payment_method_for_customer,
        :make_default,
        :skip_advanced_fraud_checking,
        :venmo_sdk_session, # Deprecated
        :verification_account_type,
        :verification_amount,
        :verification_currency_iso_code,
        :verification_merchant_account_id,
        :verify_card
      ]
      # NEXT_MAJOR_VERSION Remove venmo_sdk_payment_method_code
      # The old venmo SDK class has been deprecated
      signature = [
        :billing_address_id, :cardholder_name, :cvv, :expiration_date, :expiration_month,
        :expiration_year, :number, :token, :venmo_sdk_payment_method_code, # Deprecated
        :device_data, :payment_method_nonce,
        {:external_vault => [:network_transaction_id]},
        {:options => options},
        {:billing_address => billing_address_params}
      ]

      signature << {
        :three_d_secure_pass_thru => [
          :eci_flag,
          :cavv,
          :xid,
          :three_d_secure_version,
          :authentication_response,
          :directory_response,
          :cavv_algorithm,
          :ds_transaction_id,
        ]
      }

      case type
      when :create
        signature << :customer_id
      when :update
        billing_address_params << {:options => [:update_existing]}
      else
        raise ArgumentError
      end

      return signature
    end

    def _do_create(path, params=nil)
      response = @config.http.post("#{@config.base_merchant_path}#{path}", params)
      if response[:credit_card]
        SuccessfulResult.new(:credit_card => CreditCard._new(@gateway, response[:credit_card]))
      elsif response[:api_error_response]
        ErrorResult.new(@gateway, response[:api_error_response])
      else
        raise UnexpectedError, "expected :credit_card or :api_error_response"
      end
    end

    def _do_update(http_verb, path, params)
      response = @config.http.send(http_verb, "#{@config.base_merchant_path}#{path}", params)
      if response[:credit_card]
        SuccessfulResult.new(:credit_card => CreditCard._new(@gateway, response[:credit_card]))
      elsif response[:api_error_response]
        ErrorResult.new(@gateway, response[:api_error_response])
      else
        raise UnexpectedError, "expected :credit_card or :api_error_response"
      end
    end

    def _fetch_expired(ids)
      response = @config.http.post("#{@config.base_merchant_path}/payment_methods/all/expired", :search => {:ids => ids})
      attributes = response[:payment_methods]
      Util.extract_attribute_as_array(attributes, :credit_card).map { |attrs| CreditCard._new(@gateway, attrs) }
    end

    def _fetch_expiring_between(formatted_start_date, formatted_end_date, ids)
      response = @config.http.post(
        "#{@config.base_merchant_path}/payment_methods/all/expiring?start=#{formatted_start_date}&end=#{formatted_end_date}",
        :search => {:ids => ids},
      )
      attributes = response[:payment_methods]
      Util.extract_attribute_as_array(attributes, :credit_card).map { |attrs| CreditCard._new(@gateway, attrs) }
    end
  end
end
