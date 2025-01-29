module Braintree
  class Transaction
    include BaseModule
    include Braintree::Util::IdEquality

    module CreatedUsing
      FullInformation = "full_information"
      Token = "token"
      Unrecognized = "unrecognized"
    end

    module EscrowStatus
      HoldPending    = "hold_pending"
      Held           = "held"
      ReleasePending = "release_pending"
      Released       = "released"
      Refunded       = "refunded"
      Unrecognized   = "unrecognized"
    end

    module GatewayRejectionReason
      ApplicationIncomplete = "application_incomplete"
      AVS          = "avs"
      AVSAndCVV    = "avs_and_cvv"
      CVV          = "cvv"
      Duplicate    = "duplicate"
      ExcessiveRetry = "excessive_retry"
      Fraud        = "fraud"
      RiskThreshold = "risk_threshold"
      ThreeDSecure = "three_d_secure"
      TokenIssuance = "token_issuance"
      Unrecognized = "unrecognized"
    end

    module Status
      AuthorizationExpired   = "authorization_expired"
      Authorizing            = "authorizing"
      Authorized             = "authorized"
      GatewayRejected        = "gateway_rejected"
      Failed                 = "failed"
      ProcessorDeclined      = "processor_declined"
      Settled                = "settled"
      SettlementConfirmed    = "settlement_confirmed"
      SettlementDeclined     = "settlement_declined"
      SettlementPending      = "settlement_pending"
      Settling               = "settling"
      SubmittedForSettlement = "submitted_for_settlement"
      Voided                 = "voided"
      Unrecognized           = "unrecognized"

      All = constants.map { |c| const_get(c) }
    end

    module Source
      Api          = "api"
      ControlPanel = "control_panel"
      Recurring    = "recurring"
      Unrecognized = "unrecognized"
    end

    module IndustryType
      Lodging = "lodging"
      TravelAndCruise = "travel_cruise"
      TravelAndFlight = "travel_flight"

      All = constants.map { |c| const_get(c) }
    end

    module AdditionalCharge
      Restaurant = "restaurant"
      GiftShop = "gift_shop"
      MiniBar = "mini_bar"
      Telephone = "telephone"
      Laundry = "laundry"
      Other = "other"

      All = constants.map { |c| const_get(c) }
    end

    module Type
      Credit = "credit"
      Sale = "sale"

      All = constants.map { |c| const_get(c) }
    end

    module ExternalVault
      module Status
        WillVault = "will_vault"
        Vaulted = "vaulted"
      end
    end

    attr_reader :ach_return_code
    attr_reader :ach_return_responses
    attr_reader :acquirer_reference_number
    attr_reader :add_ons
    attr_reader :additional_processor_response          # The raw response from the processor.
    attr_reader :amount
    attr_reader :apple_pay_details
    attr_reader :authorization_adjustments
    attr_reader :authorization_expires_at
    attr_reader :authorized_transaction_id
    attr_reader :avs_error_response_code
    attr_reader :avs_postal_code_response_code
    attr_reader :avs_street_address_response_code
    attr_reader :billing_details
    attr_reader :channel
    attr_reader :created_at
    attr_reader :credit_card_details
    attr_reader :currency_iso_code
    attr_reader :custom_fields
    attr_reader :customer_details
    attr_reader :cvv_response_code
    attr_reader :debit_network
    attr_reader :descriptor
    attr_reader :disbursement_details
    attr_reader :discount_amount
    attr_reader :discounts
    attr_reader :disputes
    attr_reader :escrow_status
    attr_reader :facilitated_details
    attr_reader :facilitator_details
    attr_reader :foreign_retailer
    attr_reader :gateway_rejection_reason
    attr_reader :google_pay_details
    attr_reader :graphql_id
    attr_reader :id
    attr_reader :installment_count
    attr_reader :installments
    attr_reader :local_payment_details
    attr_reader :merchant_account_id
    attr_reader :merchant_advice_code
    attr_reader :merchant_advice_code_text
    attr_reader :meta_checkout_card_details
    attr_reader :meta_checkout_token_details
    attr_reader :network_response_code                  # Response code from the card network
    attr_reader :network_response_text                  # Response text from the card network
    attr_reader :network_token_details
    attr_reader :network_transaction_id
    attr_reader :order_id
    attr_reader :packages
    attr_reader :partial_settlement_transaction_ids
    attr_reader :payment_instrument_type
    attr_reader :payment_receipt
    attr_reader :paypal_details
    attr_reader :paypal_here_details
    attr_reader :plan_id
    attr_reader :processor_authorization_code
    attr_reader :processor_response_code
    attr_reader :processor_response_text
    attr_reader :processor_response_type
    attr_reader :processor_settlement_response_code
    attr_reader :processor_settlement_response_text
    attr_reader :product_sku
    attr_reader :purchase_order_number
    attr_reader :recurring
    attr_reader :refund_ids
    attr_reader :refunded_installments
    attr_reader :refunded_transaction_id
    attr_reader :retried
    attr_reader :retried_transaction_id                 # the primary/parent transaction id of any retried transaction
    attr_reader :retrieval_reference_number
    attr_reader :retry_ids                              # all retried transactions ids for a primary transaction
    attr_reader :risk_data
    attr_reader :samsung_pay_card_details
    attr_reader :sca_exemption_requested
    attr_reader :sepa_direct_debit_account_details
    attr_reader :sepa_direct_debit_return_code
    attr_reader :service_fee_amount
    attr_reader :settlement_batch_id
    attr_reader :shipping_amount
    attr_reader :shipping_details
    attr_reader :shipping_tax_amount
    attr_reader :ships_from_postal_code
    attr_reader :status                                 # See Transaction::Status
    attr_reader :status_history
    attr_reader :subscription_details
    attr_reader :subscription_id
    attr_reader :tax_amount
    attr_reader :tax_exempt
    attr_reader :three_d_secure_info
    attr_reader :type
    attr_reader :updated_at
    attr_reader :us_bank_account_details
    attr_reader :venmo_account_details
    attr_reader :visa_checkout_card_details
    attr_reader :voice_referral_number

    def self.adjust_authorization(*args)
      Configuration.gateway.transaction.adjust_authorization(*args)
    end

    def self.adjust_authorization!(*args)
      Configuration.gateway.transaction.adjust_authorization!(*args)
    end

    def self.create(*args)
      Configuration.gateway.transaction.create(*args)
    end

    def self.create!(*args)
      return_object_or_raise(:transaction) { create(*args) }
    end

    def self.cancel_release(*args)
      Configuration.gateway.transaction.cancel_release(*args)
    end

    def self.cancel_release!(*args)
      Configuration.gateway.transaction.cancel_release!(*args)
    end

    def self.clone_transaction(*args)
      Configuration.gateway.transaction.clone_transaction(*args)
    end

    def self.clone_transaction!(*args)
      Configuration.gateway.transaction.clone_transaction!(*args)
    end

    def self.credit(*args)
      Configuration.gateway.transaction.credit(*args)
    end

    def self.credit!(*args)
      Configuration.gateway.transaction.credit!(*args)
    end

    def self.find(*args)
      Configuration.gateway.transaction.find(*args)
    end

    def self.line_items(*args)
      Configuration.gateway.transaction_line_item.find_all(*args)
    end

    def self.hold_in_escrow(*args)
      Configuration.gateway.transaction.hold_in_escrow(*args)
    end

    def self.hold_in_escrow!(*args)
      Configuration.gateway.transaction.hold_in_escrow!(*args)
    end

    def self.refund(*args)
      Configuration.gateway.transaction.refund(*args)
    end

    def self.refund!(*args)
      Configuration.gateway.transaction.refund!(*args)
    end

    def self.sale(*args)
      Configuration.gateway.transaction.sale(*args)
    end

    def self.sale!(*args)
      Configuration.gateway.transaction.sale!(*args)
    end

    def self.search(&block)
      Configuration.gateway.transaction.search(&block)
    end

    def self.release_from_escrow(*args)
      Configuration.gateway.transaction.release_from_escrow(*args)
    end

    def self.release_from_escrow!(*args)
      Configuration.gateway.transaction.release_from_escrow!(*args)
    end

    def self.submit_for_settlement(*args)
      Configuration.gateway.transaction.submit_for_settlement(*args)
    end

    def self.submit_for_settlement!(*args)
      Configuration.gateway.transaction.submit_for_settlement!(*args)
    end

    def self.update_details(*args)
      Configuration.gateway.transaction.update_details(*args)
    end

    def self.update_details!(*args)
      return_object_or_raise(:transaction) { update_details(*args) }
    end

    def self.package_tracking(*args)
      Configuration.gateway.transaction.package_tracking(*args)
    end

    def self.package_tracking!(*args)
      Configuration.gateway.transaction.package_tracking!(*args)
    end

    def self.submit_for_partial_settlement(*args)
      Configuration.gateway.transaction.submit_for_partial_settlement(*args)
    end

    def self.submit_for_partial_settlement!(*args)
      Configuration.gateway.transaction.submit_for_partial_settlement!(*args)
    end

    def self.void(*args)
      Configuration.gateway.transaction.void(*args)
    end

    def self.void!(*args)
      Configuration.gateway.transaction.void!(*args)
    end

    # NEXT_MAJOR_VERSION remove SamsungPayCardDetails
    def initialize(gateway, attributes)
      @gateway = gateway
      set_instance_variables_from_hash(attributes)

      @amount = Util.to_big_decimal(amount)
      @apple_pay_details = ApplePayDetails.new(@apple_pay)
      @billing_details = AddressDetails.new(@billing)
      @credit_card_details = CreditCardDetails.new(@credit_card)
      @network_token_details = CreditCardDetails.new(@network_token)
      @custom_fields = attributes[:custom_fields].is_a?(Hash) ? attributes[:custom_fields] : {}
      @customer_details = CustomerDetails.new(@customer)
      @descriptor = Descriptor.new(@descriptor)
      @disbursement_details = DisbursementDetails.new(@disbursement_details)
      @google_pay_details = GooglePayDetails.new(@google_pay_card)
      @local_payment_details = LocalPaymentDetails.new(@local_payment)
      @meta_checkout_card_details = MetaCheckoutCardDetails.new(attributes[:meta_checkout_card])
      @meta_checkout_token_details = MetaCheckoutTokenDetails.new(attributes[:meta_checkout_token])
      @payment_instrument_type = attributes[:payment_instrument_type]
      @payment_receipt = PaymentReceipt.new(attributes[:payment_receipt]) if attributes[:payment_receipt]
      @paypal_details = PayPalDetails.new(@paypal)
      @paypal_here_details = PayPalHereDetails.new(@paypal_here)
      @samsung_pay_card_details = SamsungPayCardDetails.new(attributes[:samsung_pay_card]) #Deprecated
      @sca_exemption_requested = attributes[:sca_exemption_requested]
      @sepa_direct_debit_account_details = SepaDirectDebitAccountDetails.new(@sepa_debit_account_detail)
      @service_fee_amount = Util.to_big_decimal(service_fee_amount)
      @packages = attributes[:shipments] ? attributes[:shipments].map { |pd| PackageDetails.new(pd) } : []
      @shipping_details = AddressDetails.new(@shipping)
      @status_history = attributes[:status_history] ? attributes[:status_history].map { |s| StatusDetails.new(s) } : []
      @subscription_details = SubscriptionDetails.new(@subscription)
      @tax_amount = Util.to_big_decimal(tax_amount)
      @venmo_account_details = VenmoAccountDetails.new(@venmo_account)
      @visa_checkout_card_details = VisaCheckoutCardDetails.new(attributes[:visa_checkout_card])

      @facilitated_details = FacilitatedDetails.new(attributes[:facilitated_details]) if attributes[:facilitated_details]
      @facilitator_details = FacilitatorDetails.new(attributes[:facilitator_details]) if attributes[:facilitator_details]
      @risk_data = RiskData.new(attributes[:risk_data]) if attributes[:risk_data]
      @three_d_secure_info = ThreeDSecureInfo.new(attributes[:three_d_secure_info]) if attributes[:three_d_secure_info]
      @us_bank_account_details = UsBankAccountDetails.new(attributes[:us_bank_account]) if attributes[:us_bank_account]

      add_ons.map! { |attrs| AddOn._new(attrs) } if add_ons
      authorization_adjustments.map! { |attrs| AuthorizationAdjustment._new(attrs) } if authorization_adjustments
      discounts.map! { |attrs| Discount._new(attrs) } if discounts
      disputes.map! { |attrs| Dispute._new(attrs) } if disputes
      installments.map! { |attrs| Installment.new(attrs) } if installments
      refunded_installments.map! { |attrs| Installment.new(attrs) } if refunded_installments
    end

    def inspect
      first = [:id, :type, :amount, :status]
      order = first + (self.class._attributes - first)
      nice_attributes = order.map do |attr|
        if attr == :amount
          Util.inspect_amount(self.amount)
        else
          "#{attr}: #{send(attr).inspect}"
        end
      end
      "#<#{self.class} #{nice_attributes.join(', ')}>"
    end

    def line_items
      @gateway.transaction_line_item.find_all(id)
    end

    def refunded?
      !@refund_id.nil?
    end

    def disbursed?
      @disbursement_details.valid?
    end

    # If this transaction was stored in the vault, or created from vault records,
    # vault_billing_address will return the associated Braintree::Address. Because the
    # vault billing address can be updated after the transaction was created, the attributes
    # on vault_billing_address may not match the attributes on billing_details.
    # NEXT_MAJOR_VERSION these methods are not documented in the developer docs, remove
    def vault_billing_address
      return nil if billing_details.id.nil?
      @gateway.address.find(customer_details.id, billing_details.id)
    end

    # If this transaction was stored in the vault, or created from vault records,
    # vault_credit_card will return the associated Braintree::CreditCard. Because the
    # vault credit card can be updated after the transaction was created, the attributes
    # on vault_credit_card may not match the attributes on credit_card_details.
    # NEXT_MAJOR_VERSION these methods are not documented in the developer docs, remove
    def vault_credit_card
      return nil if credit_card_details.token.nil?
      @gateway.credit_card.find(credit_card_details.token)
    end

    # If this transaction was stored in the vault, or created from vault records,
    # vault_customer will return the associated Braintree::Customer. Because the
    # vault customer can be updated after the transaction was created, the attributes
    # on vault_customer may not match the attributes on customer_details.
    # NEXT_MAJOR_VERSION these methods are not documented in the developer docs, remove
    def vault_customer
      return nil if customer_details.id.nil?
      @gateway.customer.find(customer_details.id)
    end

    # If this transaction was stored in the vault, or created from vault records,
    # vault_shipping_address will return the associated Braintree::Address. Because the
    # vault shipping address can be updated after the transaction was created, the attributes
    # on vault_shipping_address may not match the attributes on shipping_details.
    # NEXT_MAJOR_VERSION these methods are not documented in the developer docs, remove
    def vault_shipping_address
      return nil if shipping_details.id.nil?
      @gateway.address.find(customer_details.id, shipping_details.id)
    end

    def processed_with_network_token?
      @processed_with_network_token
    end

    class << self
      protected :new
      def _new(*args)
        self.new(*args)
      end
    end

    def self._attributes
      [:amount, :created_at, :credit_card_details, :customer_details, :id, :status, :subscription_details, :type, :updated_at, :processed_with_network_token?]
    end
  end
end
