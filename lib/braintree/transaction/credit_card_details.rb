module Braintree
  class Transaction
    class CreditCardDetails
      include BaseModule

      attr_reader :account_type
      attr_reader :bin
      attr_reader :card_type
      attr_reader :cardholder_name
      attr_reader :commercial
      attr_reader :country_of_issuance
      attr_reader :customer_location
      attr_reader :debit
      attr_reader :durbin_regulated
      attr_reader :expiration_month
      attr_reader :expiration_year
      attr_reader :healthcare
      attr_reader :image_url
      attr_reader :issuing_bank
      attr_reader :last_4
      attr_reader :payroll
      attr_reader :prepaid
      attr_reader :product_id
      attr_reader :token
      attr_reader :unique_number_identifier

      def initialize(attributes)
        set_instance_variables_from_hash attributes unless attributes.nil?
      end

      def expiration_date
        "#{expiration_month}/#{expiration_year}"
      end

      def inspect
        attr_order = [
          :token,
          :bin,
          :last_4,
          :card_type,
          :expiration_date,
          :cardholder_name,
          :customer_location,
          :prepaid,
          :healthcare,
          :durbin_regulated,
          :debit,
          :commercial,
          :payroll,
          :product_id,
          :country_of_issuance,
          :issuing_bank,
          :image_url,
          :unique_number_identifier,
        ]

        formatted_attrs = attr_order.map do |attr|
          "#{attr}: #{send(attr).inspect}"
        end
        "#<#{formatted_attrs.join(", ")}>"
      end

      def masked_number
        "#{bin}******#{last_4}"
      end

      # NEXT_MAJOR_VERSION Remove this method
      # The old venmo SDK class has been deprecated
      def venmo_sdk?
        warn "[DEPRECATED] The Venmo SDK integration is Unsupported. Please update your integration to use Pay with Venmo instead."
        @venmo_sdk
      end

      def is_network_tokenized?
        @is_network_tokenized
      end
    end
  end
end
