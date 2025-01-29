require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")
require File.expand_path(File.dirname(__FILE__) + "/client_api/spec_helper")

describe Braintree::Transaction, "search" do
  context "advanced" do
    it "correctly returns a result with no matches" do
      collection = Braintree::Transaction.search do |search|
        search.billing_first_name.is "thisnameisnotreal"
      end

      expect(collection.maximum_size).to eq(0)
    end

    #Disabling test until we have more stable CI
    xit "can search on text fields" do
      first_name = "Tim_#{rand(10**10)}"
      token = "creditcard_#{rand(10**10)}"
      customer_id = "customer_#{rand(10**10)}"

      transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2012",
          :cardholder_name => "Tom Smith",
          :token => token,
        },
        :billing => {
          :company => "Braintree",
          :country_name => "United States of America",
          :extended_address => "Suite 123",
          :first_name => first_name,
          :last_name => "Smith",
          :locality => "Chicago",
          :postal_code => "12345",
          :region => "IL",
          :street_address => "123 Main St"
        },
        :customer => {
          :company => "Braintree",
          :email => "smith@example.com",
          :fax => "5551231234",
          :first_name => "Tom",
          :id => customer_id,
          :last_name => "Smith",
          :phone => "5551231234",
          :website => "http://example.com",
        },
        :options => {
          :store_in_vault => true,
          :submit_for_settlement => true
        },
        :order_id => "myorder",
        :shipping => {
          :company => "Braintree P.S.",
          :country_name => "Mexico",
          :extended_address => "Apt 456",
          :first_name => "Thomas",
          :last_name => "Smithy",
          :locality => "Braintree",
          :postal_code => "54321",
          :region => "MA",
          :street_address => "456 Road"
        },
      )

      SpecHelper.settle_transaction transaction.id
      transaction = Braintree::Transaction.find(transaction.id)
      credit_card = Braintree::CreditCard.find(token)

      search_criteria = {
        :billing_company => "Braintree",
        :billing_country_name => "United States of America",
        :billing_extended_address => "Suite 123",
        :billing_first_name => first_name,
        :billing_last_name => "Smith",
        :billing_locality => "Chicago",
        :billing_postal_code => "12345",
        :billing_region => "IL",
        :billing_street_address => "123 Main St",
        :credit_card_cardholder_name => "Tom Smith",
        :credit_card_expiration_date => "05/2012",
        :credit_card_number => Braintree::Test::CreditCardNumbers::Visa,
        :credit_card_unique_identifier => credit_card.unique_number_identifier,
        :customer_company => "Braintree",
        :customer_email => "smith@example.com",
        :customer_fax => "5551231234",
        :customer_first_name => "Tom",
        :customer_id => customer_id,
        :customer_last_name => "Smith",
        :customer_phone => "5551231234",
        :customer_website => "http://example.com",
        :order_id => "myorder",
        :payment_method_token => token,
        :processor_authorization_code => transaction.processor_authorization_code,
        :settlement_batch_id => transaction.settlement_batch_id,
        :shipping_company => "Braintree P.S.",
        :shipping_country_name => "Mexico",
        :shipping_extended_address => "Apt 456",
        :shipping_first_name => "Thomas",
        :shipping_last_name => "Smithy",
        :shipping_locality => "Braintree",
        :shipping_postal_code => "54321",
        :shipping_region => "MA",
        :shipping_street_address => "456 Road"
      }

      search_criteria.each do |criterion, value|
        collection = Braintree::Transaction.search do |search|
          search.id.is transaction.id
          search.send(criterion).is value
        end
        expect(collection.maximum_size).to eq(1)
        expect(collection.first.id).to eq(transaction.id)

        collection = Braintree::Transaction.search do |search|
          search.id.is transaction.id
          search.send(criterion).is("invalid_attribute")
        end
        expect(collection).to be_empty
      end

      collection = Braintree::Transaction.search do |search|
        search.id.is transaction.id
        search_criteria.each do |criterion, value|
          search.send(criterion).is value
        end
      end

      expect(collection.maximum_size).to eq(1)
      expect(collection.first.id).to eq(transaction.id)
    end

    #Disabling test until we have more stable CI
    xit "searches on users" do
      transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :payment_method_nonce => Braintree::Test::Nonce::PayPalBillingAgreement,
      )

      collection = Braintree::Transaction.search do |search|
        search.user.is "integration_user_public_id"
      end

      expect(collection.any? { |t| t.id == transaction.id }).to eq(true)
    end

    it "searches on paypal transactions" do
      transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :payment_method_nonce => Braintree::Test::Nonce::PayPalBillingAgreement,
      )

      paypal_details = transaction.paypal_details

      collection = Braintree::Transaction.search do |search|
        search.paypal_payment_id.is paypal_details.payment_id
        search.paypal_authorization_id.is paypal_details.authorization_id
        search.paypal_payer_email.is paypal_details.payer_email
      end

      expect(collection.maximum_size).to eq(1)
      expect(collection.first.id).to eq(transaction.id)
    end

    it "searches on store_id" do
      transaction_id = "contact_visa_transaction"
      store_id = "store-id"

      collection = Braintree::Transaction.search do |search|
        search.id.is transaction_id
        search.store_ids.in store_id
      end

      expect(collection.maximum_size).to eq(1)
      expect(collection.first.id).to eq(transaction_id)
    end

    it "searches on reason_code" do
      transaction_id = "ach_txn_ret1"
      reason_code = "R01"

      collection = Braintree::Transaction.search do |search|
        search.reason_code.in reason_code
      end

      expect(collection.maximum_size).to eq(1)
      expect(collection.first.id).to eq(transaction_id)
      expect(collection.first.ach_return_responses.first[:reason_code]).to eq("R01")
    end

    it "searches on reason_codes" do
      reason_code = "any_reason_code"

      collection = Braintree::Transaction.search do |search|
        search.reason_code.is reason_code
      end

      expect(collection.maximum_size).to eq(2)
    end

    context "multiple value fields" do
      it "searches on created_using" do
        transaction = Braintree::Transaction.sale!(
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/12"
        },
        )

        collection = Braintree::Transaction.search do |search|
          search.id.is transaction.id
          search.created_using.is Braintree::Transaction::CreatedUsing::FullInformation
        end

        expect(collection.maximum_size).to eq(1)

        collection = Braintree::Transaction.search do |search|
          search.id.is transaction.id
          search.created_using.in Braintree::Transaction::CreatedUsing::FullInformation, Braintree::Transaction::CreatedUsing::Token
        end

        expect(collection.maximum_size).to eq(1)

        collection = Braintree::Transaction.search do |search|
          search.id.is transaction.id
          search.created_using.is Braintree::Transaction::CreatedUsing::Token
        end

        expect(collection.maximum_size).to eq(0)
      end

      it "searches on credit_card_customer_location" do
        transaction = Braintree::Transaction.sale!(
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/12"
        },
        )

        collection = Braintree::Transaction.search do |search|
          search.id.is transaction.id
          search.credit_card_customer_location.is Braintree::CreditCard::CustomerLocation::US
        end

        expect(collection.maximum_size).to eq(1)

        collection = Braintree::Transaction.search do |search|
          search.id.is transaction.id
          search.credit_card_customer_location.in Braintree::CreditCard::CustomerLocation::US, Braintree::CreditCard::CustomerLocation::International
        end

        expect(collection.maximum_size).to eq(1)

        collection = Braintree::Transaction.search do |search|
          search.id.is transaction.id
          search.credit_card_customer_location.is Braintree::CreditCard::CustomerLocation::International
        end

        expect(collection.maximum_size).to eq(0)
      end

      it "searches on merchant_account_id" do
        transaction = Braintree::Transaction.sale!(
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/12"
        },
        )

        collection = Braintree::Transaction.search do |search|
          search.id.is transaction.id
          search.merchant_account_id.is transaction.merchant_account_id
        end

        expect(collection.maximum_size).to eq(1)

        collection = Braintree::Transaction.search do |search|
          search.id.is transaction.id
          search.merchant_account_id.in transaction.merchant_account_id, "bogus_merchant_account_id"
        end

        expect(collection.maximum_size).to eq(1)

        collection = Braintree::Transaction.search do |search|
          search.id.is transaction.id
          search.merchant_account_id.is "bogus_merchant_account_id"
        end

        expect(collection.maximum_size).to eq(0)
      end

      it "searches on credit_card_card_type" do
        transaction = Braintree::Transaction.sale!(
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/12"
        },
        )

        collection = Braintree::Transaction.search do |search|
          search.id.is transaction.id
          search.credit_card_card_type.is Braintree::CreditCard::CardType::Visa
        end

        expect(collection.maximum_size).to eq(1)

        collection = Braintree::Transaction.search do |search|
          search.id.is transaction.id
          search.credit_card_card_type.is transaction.credit_card_details.card_type
        end

        expect(collection.maximum_size).to eq(1)

        collection = Braintree::Transaction.search do |search|
          search.id.is transaction.id
          search.credit_card_card_type.in Braintree::CreditCard::CardType::Visa, Braintree::CreditCard::CardType::MasterCard
        end

        expect(collection.maximum_size).to eq(1)

        collection = Braintree::Transaction.search do |search|
          search.id.is transaction.id
          search.credit_card_card_type.is Braintree::CreditCard::CardType::MasterCard
        end

        expect(collection.maximum_size).to eq(0)
      end

      it "searches for an Elo card" do
        transaction = Braintree::Transaction.sale!(
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :merchant_account_id => SpecHelper::AdyenMerchantAccountId,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Elo,
            :cvv => "737",
            :expiration_date => "10/2020"
          },
        )

        collection = Braintree::Transaction.search do |search|
          search.id.is transaction.id
          search.credit_card_card_type.is Braintree::CreditCard::CardType::Elo
        end

        expect(collection.maximum_size).to eq(1)
      end

      it "searches by payment instrument type CreditCardDetail" do
        transaction = Braintree::Transaction.sale!(
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/12"
          },
        )

        collection = Braintree::Transaction.search do |search|
          search.id.is transaction.id
          search.payment_instrument_type.in ["CreditCardDetail"]
        end

        expect(collection.first.id).to eq(transaction.id)
        expect(collection.first.payment_instrument_type).to eq(Braintree::PaymentInstrumentType::CreditCard)
      end

      it "searches by payment instrument type PayPal" do
        transaction = Braintree::Transaction.sale!(
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :payment_method_nonce => Braintree::Test::Nonce::PayPalFuturePayment,
        )

        collection = Braintree::Transaction.search do |search|
          search.id.is transaction.id
          search.payment_instrument_type.in ["PayPalDetail"]
        end

        expect(collection.first.id).to eq(transaction.id)
        expect(collection.first.payment_instrument_type).to eq(Braintree::PaymentInstrumentType::PayPalAccount)
      end

      it "searches by payment instrument type LocalPaymentDetail" do
        transaction = Braintree::Transaction.sale!(
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :payment_method_nonce => Braintree::Test::Nonce::LocalPayment,
        )

        collection = Braintree::Transaction.search do |search|
          search.id.is transaction.id
          search.payment_instrument_type.in ["LocalPaymentDetail"]
        end

        expect(collection.first.id).to eq(transaction.id)
        expect(collection.first.payment_instrument_type).to eq(Braintree::PaymentInstrumentType::LocalPayment)
      end

      it "searches by payment instrument type SepaDebitAccountDetail" do
        transaction = Braintree::Transaction.sale!(
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :payment_method_nonce => Braintree::Test::Nonce::SepaDirectDebit,
          :options => {:submit_for_settlement => true},
        )

        collection = Braintree::Transaction.search do |search|
          search.id.is transaction.id
          search.payment_instrument_type.in ["SEPADebitAccountDetail"]
        end

        expect(collection.first.id).to eq(transaction.id)
        expect(collection.first.payment_instrument_type).to eq(Braintree::PaymentInstrumentType::SepaDirectDebitAccount)
      end

      it "searches by paypal_v2_order_id" do
        transaction = Braintree::Transaction.sale!(
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :payment_method_nonce => Braintree::Test::Nonce::SepaDirectDebit,
          :options => {:submit_for_settlement => true},
        )

        collection = Braintree::Transaction.search do |search|
          search.id.is transaction.id
          search.sepa_debit_paypal_v2_order_id.is transaction.sepa_direct_debit_account_details.paypal_v2_order_id
        end

        expect(collection.first.id).to eq(transaction.id)
        expect(collection.first.payment_instrument_type).to eq(Braintree::PaymentInstrumentType::SepaDirectDebitAccount)
      end

      it "searches by payment instrument type ApplePay" do
        transaction = Braintree::Transaction.sale!(
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :payment_method_nonce => Braintree::Test::Nonce::ApplePayVisa,
        )

        collection = Braintree::Transaction.search do |search|
          search.id.is transaction.id
          search.payment_instrument_type.in ["ApplePayDetail"]
        end

        expect(collection.first.id).to eq(transaction.id)
        expect(collection.first.payment_instrument_type).to eq(Braintree::PaymentInstrumentType::ApplePayCard)
      end

      it "searches on status" do
        transaction = Braintree::Transaction.sale!(
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/12"
          },
        )

        collection = Braintree::Transaction.search do |search|
          search.id.is transaction.id
          search.status.is Braintree::Transaction::Status::Authorized
        end

        expect(collection.maximum_size).to eq(1)

        collection = Braintree::Transaction.search do |search|
          search.id.is transaction.id
          search.status.in Braintree::Transaction::Status::Authorized, Braintree::Transaction::Status::ProcessorDeclined
        end

        expect(collection.maximum_size).to eq(1)

        collection = Braintree::Transaction.search do |search|
          search.id.is transaction.id
          search.status.is Braintree::Transaction::Status::ProcessorDeclined
        end

        expect(collection.maximum_size).to eq(0)
      end

      it "searches for settlement_confirmed transaction" do
        transaction_id = "settlement_confirmed_txn"

        collection = Braintree::Transaction.search do |search|
          search.id.is transaction_id
        end

        expect(collection.maximum_size).to eq(1)
        expect(collection.first.id).to eq(transaction_id)
      end

      it "finds expired authorizations by status" do
        collection = Braintree::Transaction.search do |search|
          search.status.in Braintree::Transaction::Status::AuthorizationExpired
        end

        expect(collection.maximum_size).to be > 0
        expect(collection.first.status).to eq(Braintree::Transaction::Status::AuthorizationExpired)
      end

      it "searches on source" do
        transaction = Braintree::Transaction.sale!(
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/12"
          },
        )

        collection = Braintree::Transaction.search do |search|
          search.id.is transaction.id
          search.source.is Braintree::Transaction::Source::Api
        end

        expect(collection.maximum_size).to eq(1)

        collection = Braintree::Transaction.search do |search|
          search.id.is transaction.id
          search.source.in Braintree::Transaction::Source::Api, Braintree::Transaction::Source::ControlPanel
        end

        expect(collection.maximum_size).to eq(1)

        collection = Braintree::Transaction.search do |search|
          search.id.is transaction.id
          search.source.is Braintree::Transaction::Source::ControlPanel
        end

        expect(collection.maximum_size).to eq(0)
      end

      it "searches on type" do
        cardholder_name = "refunds#{rand(10000)}"
        credit_transaction = Braintree::Transaction.credit!(
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
          :cardholder_name => cardholder_name,
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/12"
        },
        )

        transaction = Braintree::Transaction.sale!(
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
          :cardholder_name => cardholder_name,
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/12"
        },
        :options => {:submit_for_settlement => true},
        )
        SpecHelper.settle_transaction transaction.id

        refund_transaction = Braintree::Transaction.refund(transaction.id).transaction

        collection = Braintree::Transaction.search do |search|
          search.credit_card_cardholder_name.is cardholder_name
          search.type.is Braintree::Transaction::Type::Credit
        end

        expect(collection.maximum_size).to eq(2)

        collection = Braintree::Transaction.search do |search|
          search.credit_card_cardholder_name.is cardholder_name
          search.type.is Braintree::Transaction::Type::Credit
          search.refund.is true
        end

        expect(collection.maximum_size).to eq(1)
        expect(collection.first.id).to eq(refund_transaction.id)

        collection = Braintree::Transaction.search do |search|
          search.credit_card_cardholder_name.is cardholder_name
          search.type.is Braintree::Transaction::Type::Credit
          search.refund.is false
        end

        expect(collection.maximum_size).to eq(1)
        expect(collection.first.id).to eq(credit_transaction.id)
      end

      it "searches on store_ids" do
        transaction_id = "contact_visa_transaction"
        store_ids = ["store-id"]

        collection = Braintree::Transaction.search do |search|
          search.id.is transaction_id
          search.store_ids.in store_ids
        end

        expect(collection.maximum_size).to eq(1)
        expect(collection.first.id).to eq(transaction_id)
      end

      it "searches on reason_codes for 2 items" do
        reason_code = ["R01", "R02"]

        collection = Braintree::Transaction.search do |search|
          search.reason_code.in reason_code
        end

        expect(collection.maximum_size).to eq(2)
      end

      it "searches on a reason_code" do
        reason_code = ["R01"]
        transaction_id = "ach_txn_ret1"

        collection = Braintree::Transaction.search do |search|
          search.reason_code.in reason_code
        end

        expect(collection.maximum_size).to eq(1)
        expect(collection.first.id).to eq(transaction_id)
      end

      xit "searches on debit_network" do
        transaction = Braintree::Transaction.sale!(
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :merchant_account_id => SpecHelper::PinlessDebitMerchantAccountId,
          :currency_iso_code => "USD",
          :payment_method_nonce => Braintree::Test::Nonce::TransactablePinlessDebitVisa,
          :options => {
            :submit_for_settlement => true
          },
        )

        collection = Braintree::Transaction.search do |search|
          search.id.is transaction.id
          search.credit_card_card_type.is Braintree::CreditCard::CardType::Visa
        end

        expect(collection.maximum_size).to be > 0

        collection = Braintree::Transaction.search do |search|
          search.id.is transaction.id
          search.debit_network.in Braintree::CreditCard::DebitNetwork::All
        end

        expect(collection.maximum_size).to be > 0
      end
    end

    context "invalid search" do
      it "raises an exception on invalid transaction type" do
        expect do
          Braintree::Transaction.search do |search|
            search.customer_id.is "9171566"
            search.type.is "settled"
          end
        end.to raise_error(ArgumentError)
      end

      it "raises an exception on invalid debit network" do
        expect do
          Braintree::Transaction.search do |search|
            search.debit_network.is "invalid_network"
          end
        end.to raise_error(ArgumentError)
      end
    end

    context "range fields" do
      context "amount" do
        it "searches on amount" do
          transaction = Braintree::Transaction.sale!(
            :amount => "1000.00",
            :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/12"
          },
          )

          collection = Braintree::Transaction.search do |search|
            search.id.is transaction.id
            search.amount.between "500.00", "1500.00"
          end

          expect(collection.maximum_size).to eq(1)
          expect(collection.first.id).to eq(transaction.id)

          collection = Braintree::Transaction.search do |search|
            search.id.is transaction.id
            search.amount >= "500.00"
          end

          expect(collection.maximum_size).to eq(1)
          expect(collection.first.id).to eq(transaction.id)

          collection = Braintree::Transaction.search do |search|
            search.id.is transaction.id
            search.amount <= "1500.00"
          end

          expect(collection.maximum_size).to eq(1)
          expect(collection.first.id).to eq(transaction.id)

          collection = Braintree::Transaction.search do |search|
            search.id.is transaction.id
            search.amount.between "500.00", "900.00"
          end

          expect(collection.maximum_size).to eq(0)
        end

        it "can also take BigDecimal for amount" do
          transaction = Braintree::Transaction.sale!(
            :amount => BigDecimal("1000.00"),
            :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/12"
          },
          )

          collection = Braintree::Transaction.search do |search|
            search.id.is transaction.id
            search.amount <= BigDecimal("1000.00")
          end

          expect(collection.maximum_size).to eq(1)
        end
      end

      context "created_at" do
        it "searches on created_at in UTC" do
          transaction = Braintree::Transaction.sale!(
            :amount => Braintree::Test::TransactionAmounts::Authorize,
            :credit_card => {
              :number => Braintree::Test::CreditCardNumbers::Visa,
              :expiration_date => "05/12"
            },
          )

          created_at = transaction.created_at
          expect(created_at).to be_utc

          collection = Braintree::Transaction.search do |search|
            search.id.is transaction.id
            search.created_at.between(
              created_at - 60,
              created_at + 60,
            )
          end

          expect(collection.maximum_size).to eq(1)
          expect(collection.first.id).to eq(transaction.id)

          collection = Braintree::Transaction.search do |search|
            search.id.is transaction.id
            search.created_at >= created_at - 1
          end

          expect(collection.maximum_size).to eq(1)
          expect(collection.first.id).to eq(transaction.id)

          collection = Braintree::Transaction.search do |search|
            search.id.is transaction.id
            search.created_at <= created_at + 1
          end

          expect(collection.maximum_size).to eq(1)
          expect(collection.first.id).to eq(transaction.id)

          collection = Braintree::Transaction.search do |search|
            search.id.is transaction.id
            search.created_at.between(
              created_at - 300,
              created_at - 100,
            )
          end

          expect(collection.maximum_size).to eq(0)

          collection = Braintree::Transaction.search do |search|
            search.id.is transaction.id
            search.created_at.is created_at
          end

          expect(collection.maximum_size).to eq(1)
          expect(collection.first.id).to eq(transaction.id)
        end

        it "searches on created_at in local time" do
          transaction = Braintree::Transaction.sale!(
            :amount => Braintree::Test::TransactionAmounts::Authorize,
            :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/12"
          },
          )

          now = Time.now

          collection = Braintree::Transaction.search do |search|
            search.id.is transaction.id
            search.created_at.between(
              now - 60,
              now + 60,
            )
          end

          expect(collection.maximum_size).to eq(1)
          expect(collection.first.id).to eq(transaction.id)

          collection = Braintree::Transaction.search do |search|
            search.id.is transaction.id
            search.created_at >= now - 60
          end

          expect(collection.maximum_size).to eq(1)
          expect(collection.first.id).to eq(transaction.id)

          collection = Braintree::Transaction.search do |search|
            search.id.is transaction.id
            search.created_at <= now + 60
          end

          expect(collection.maximum_size).to eq(1)
          expect(collection.first.id).to eq(transaction.id)

          collection = Braintree::Transaction.search do |search|
            search.id.is transaction.id
            search.created_at.between(
              now - 300,
              now - 100,
            )
          end

          expect(collection.maximum_size).to eq(0)
        end

        it "searches on created_at with dates" do
          transaction = Braintree::Transaction.sale!(
            :amount => Braintree::Test::TransactionAmounts::Authorize,
            :credit_card => {
              :number => Braintree::Test::CreditCardNumbers::Visa,
              :expiration_date => "05/12"
            },
          )

          collection = Braintree::Transaction.search do |search|
            search.id.is transaction.id
            search.created_at.between(
              Date.today - 1,
              Date.today + 1,
            )
          end

          expect(collection.maximum_size).to eq(1)
          expect(collection.first.id).to eq(transaction.id)
        end
      end

      context "ach return response created at" do
        it "it finds records within date range of the custom field" do
          date_search = Braintree::Transaction.search do |search|
            search.ach_return_responses_created_at.between(DateTime.now - 1.0, DateTime.now + 1.0)
          end

          expect(date_search.maximum_size).to eq(2)
        end

        it "it does not find records not within date range of the custom field" do
          neg_date_search = Braintree::Transaction.search do |search|
           search.ach_return_responses_created_at.between(DateTime.now + 1.0, DateTime.now - 1.0)
          end

          expect(neg_date_search.maximum_size).to eq(0)
        end
      end

      context "disbursement_date" do
        it "searches on disbursement_date in UTC, as a date" do
          disbursement_time = Date.parse("2013-04-10")
          transaction_id = "deposittransaction"

          collection = Braintree::Transaction.search do |search|
            search.id.is transaction_id
            search.disbursement_date.between(
              disbursement_time - 60,
              disbursement_time + 60,
            )
          end

          expect(collection.maximum_size).to eq(1)
          expect(collection.first.id).to eq(transaction_id)

          collection = Braintree::Transaction.search do |search|
            search.id.is transaction_id
            search.disbursement_date >= disbursement_time - 1
          end

          expect(collection.maximum_size).to eq(1)
          expect(collection.first.id).to eq(transaction_id)

          collection = Braintree::Transaction.search do |search|
            search.id.is transaction_id
            search.disbursement_date <= disbursement_time + 1
          end

          expect(collection.maximum_size).to eq(1)
          expect(collection.first.id).to eq(transaction_id)

          collection = Braintree::Transaction.search do |search|
            search.id.is transaction_id
            search.disbursement_date.between(
              disbursement_time - 300,
              disbursement_time - 100,
            )
          end

          expect(collection.maximum_size).to eq(0)

          collection = Braintree::Transaction.search do |search|
            search.id.is transaction_id
            search.disbursement_date.is disbursement_time
          end

          expect(collection.maximum_size).to eq(1)
          expect(collection.first.id).to eq(transaction_id)
        end

        it "searches on disbursement_date in local time" do
          now = Time.parse("2013-04-09 18:00:00 CST")
          transaction_id = "deposittransaction"

          collection = Braintree::Transaction.search do |search|
            search.id.is transaction_id
            search.disbursement_date.between(
              now - 60,
              now + 60,
            )
          end

          expect(collection.maximum_size).to eq(1)
          expect(collection.first.id).to eq(transaction_id)

          collection = Braintree::Transaction.search do |search|
            search.id.is transaction_id
            search.disbursement_date >= now - 60
          end

          expect(collection.maximum_size).to eq(1)
          expect(collection.first.id).to eq(transaction_id)

          collection = Braintree::Transaction.search do |search|
            search.id.is transaction_id
            search.disbursement_date <= now + 60
          end

          expect(collection.maximum_size).to eq(1)
          expect(collection.first.id).to eq(transaction_id)

          collection = Braintree::Transaction.search do |search|
            search.id.is transaction_id
            search.disbursement_date.between(
              now - 300,
              now - 100,
            )
          end

          expect(collection.maximum_size).to eq(0)
        end

        it "searches on disbursement_date with date ranges" do
          disbursement_date = Date.new(2013, 4, 10)
          transaction_id = "deposittransaction"

          collection = Braintree::Transaction.search do |search|
            search.id.is transaction_id
            search.disbursement_date.between(
              disbursement_date - 1,
              disbursement_date + 1,
            )
          end

          expect(collection.maximum_size).to eq(1)
          expect(collection.first.id).to eq(transaction_id)
        end
      end

      context "dispute_date" do
        before(:all) do
          @disputed_transaction = Braintree::Transaction.sale!(
            :amount => Braintree::Test::TransactionAmounts::Authorize,
            :credit_card => {
              :number => Braintree::Test::CreditCardNumbers::Disputes::Chargeback,
              :expiration_date => "03/18"
            },
          )

          @disputed_date = @disputed_transaction.disputes.first.received_date
          @disputed_time = @disputed_date.to_time

          Timeout::timeout(60) {
            dispute_date_indexed = false
            until dispute_date_indexed
              sleep 1
              collection = Braintree::Transaction.search do |search|
                search.id.is @disputed_transaction.id
                search.dispute_date.is @disputed_date
              end

              dispute_date_indexed = collection.maximum_size == 1
            end
          }
        end

        xit "searches on dispute_date in UTC" do
          collection = Braintree::Transaction.search do |search|
            search.id.is @disputed_transaction.id
            search.dispute_date.between(
              @disputed_time - 60,
              @disputed_time + 60,
            )
          end

          expect(collection.maximum_size).to eq(1)
          expect(collection.first.id).to eq(@disputed_transaction.id)

          collection = Braintree::Transaction.search do |search|
            search.id.is @disputed_transaction.id
            search.dispute_date >= @disputed_time - 1
          end

          expect(collection.maximum_size).to eq(1)
          expect(collection.first.id).to eq(@disputed_transaction.id)

          collection = Braintree::Transaction.search do |search|
            search.id.is @disputed_transaction.id
            search.dispute_date <= @disputed_time + 1
          end

          expect(collection.maximum_size).to eq(1)
          expect(collection.first.id).to eq(@disputed_transaction.id)

          collection = Braintree::Transaction.search do |search|
            search.id.is @disputed_transaction.id
            search.dispute_date.is @disputed_time
          end

          expect(collection.maximum_size).to eq(1)
          expect(collection.first.id).to eq(@disputed_transaction.id)
        end

        xit "searches on dispute_date in local time" do
          now = @disputed_time.localtime("-06:00")

          collection = Braintree::Transaction.search do |search|
            search.id.is @disputed_transaction.id
            search.dispute_date.between(
              now - 60,
              now + 60,
            )
          end

          expect(collection.maximum_size).to eq(1)
          expect(collection.first.id).to eq(@disputed_transaction.id)

          collection = Braintree::Transaction.search do |search|
            search.id.is @disputed_transaction.id
            search.dispute_date >= now - 60
          end

          expect(collection.maximum_size).to eq(1)
          expect(collection.first.id).to eq(@disputed_transaction.id)

          collection = Braintree::Transaction.search do |search|
            search.id.is @disputed_transaction.id
            search.dispute_date <= now + 60
          end

          expect(collection.maximum_size).to eq(1)
        end

        xit "searches on dispute_date with date ranges" do
          collection = Braintree::Transaction.search do |search|
            search.id.is @disputed_transaction.id
            search.dispute_date.between(
              @disputed_date - 1,
              @disputed_date + 1,
            )
          end

          expect(collection.maximum_size).to eq(1)
          expect(collection.first.id).to eq(@disputed_transaction.id)
        end
      end

      context "status date ranges" do
        it "finds transactions authorized in a given range" do
          transaction = Braintree::Transaction.sale!(
            :amount => Braintree::Test::TransactionAmounts::Authorize,
            :credit_card => {
              :number => Braintree::Test::CreditCardNumbers::Visa,
              :expiration_date => "05/12"
            },
          )

          collection = Braintree::Transaction.search do |search|
            search.id.is transaction.id
            search.authorized_at.between(
              Date.today - 2,
              Date.today - 1,
            )
          end

          expect(collection.maximum_size).to eq(0)

          collection = Braintree::Transaction.search do |search|
            search.id.is transaction.id
            search.authorized_at.between(
              Date.today - 1,
              Date.today + 1,
            )
          end

          expect(collection.maximum_size).to eq(1)
          expect(collection.first.id).to eq(transaction.id)
        end

        it "finds transactions failed in a given range" do
          transaction = Braintree::Transaction.sale(
            :amount => Braintree::Test::TransactionAmounts::Fail,
            :credit_card => {
              :number => Braintree::Test::CreditCardNumbers::Visa,
              :expiration_date => "05/12"
            },
          ).transaction

          collection = Braintree::Transaction.search do |search|
            search.id.is transaction.id
            search.failed_at.between(
              Date.today - 2,
              Date.today - 1,
            )
          end

          expect(collection.maximum_size).to eq(0)

          collection = Braintree::Transaction.search do |search|
            search.id.is transaction.id
            search.failed_at.between(
              Date.today - 1,
              Date.today + 1,
            )
          end

          expect(collection.maximum_size).to eq(1)
          expect(collection.first.id).to eq(transaction.id)
        end

        it "finds expired authorizations in a given range" do
          collection = Braintree::Transaction.search do |search|
            search.authorization_expired_at.between(
              Date.today - 2,
              Date.today - 1,
            )
          end

          expect(collection.maximum_size).to eq(0)

          collection = Braintree::Transaction.search do |search|
            search.authorization_expired_at.between(
              Date.today - 1,
              Date.today + 1,
            )
          end

          expect(collection.maximum_size).to be > 0
          expect(collection.first.status).to eq(Braintree::Transaction::Status::AuthorizationExpired)
        end

        it "finds transactions gateway_rejected in a given range" do
          old_merchant = Braintree::Configuration.merchant_id
          old_public_key = Braintree::Configuration.public_key
          old_private_key = Braintree::Configuration.private_key

          begin
            Braintree::Configuration.merchant_id = "processing_rules_merchant_id"
            Braintree::Configuration.public_key = "processing_rules_public_key"
            Braintree::Configuration.private_key = "processing_rules_private_key"

            transaction = Braintree::Transaction.sale(
              :amount => Braintree::Test::TransactionAmounts::Authorize,
              :credit_card => {
                :number => Braintree::Test::CreditCardNumbers::Visa,
                :expiration_date => "05/12",
                :cvv => "200"
              },
            ).transaction

            collection = Braintree::Transaction.search do |search|
              search.id.is transaction.id
              search.gateway_rejected_at.between(
                Date.today - 2,
                Date.today - 1,
              )
            end

            expect(collection.maximum_size).to eq(0)

            collection = Braintree::Transaction.search do |search|
              search.id.is transaction.id
              search.gateway_rejected_at.between(
                Date.today - 1,
                Date.today + 1,
              )
            end

            expect(collection.maximum_size).to eq(1)
            expect(collection.first.id).to eq(transaction.id)
          ensure
            Braintree::Configuration.merchant_id = old_merchant
            Braintree::Configuration.public_key = old_public_key
            Braintree::Configuration.private_key = old_private_key
          end
        end

        it "finds transactions processor declined in a given range" do
          transaction = Braintree::Transaction.sale(
            :amount => Braintree::Test::TransactionAmounts::Decline,
            :credit_card => {
              :number => Braintree::Test::CreditCardNumbers::Visa,
              :expiration_date => "05/12"
            },
          ).transaction

          collection = Braintree::Transaction.search do |search|
            search.id.is transaction.id
            search.processor_declined_at.between(
              Date.today - 2,
              Date.today - 1,
            )
          end

          expect(collection.maximum_size).to eq(0)

          collection = Braintree::Transaction.search do |search|
            search.id.is transaction.id
            search.processor_declined_at.between(
              Date.today - 1,
              Date.today + 1,
            )
          end

          expect(collection.maximum_size).to eq(1)
          expect(collection.first.id).to eq(transaction.id)
        end

        it "finds transactions settled in a given range" do
          transaction = Braintree::Transaction.sale(
            :amount => Braintree::Test::TransactionAmounts::Authorize,
            :credit_card => {
              :number => Braintree::Test::CreditCardNumbers::Visa,
              :expiration_date => "05/12"
            },
            :options => {
              :submit_for_settlement => true
            },
          ).transaction

          SpecHelper.settle_transaction transaction.id

          collection = Braintree::Transaction.search do |search|
            search.id.is transaction.id
            search.settled_at.between(
              Date.today - 2,
              Date.today - 1,
            )
          end

          expect(collection.maximum_size).to eq(0)

          collection = Braintree::Transaction.search do |search|
            search.id.is transaction.id
            search.settled_at.between(
              Date.today - 1,
              Date.today + 1,
            )
          end

          expect(collection.maximum_size).to eq(1)
          expect(collection.first.id).to eq(transaction.id)
        end

        it "finds transactions submitted for settlement in a given range" do
          transaction = Braintree::Transaction.sale(
            :amount => Braintree::Test::TransactionAmounts::Authorize,
            :credit_card => {
              :number => Braintree::Test::CreditCardNumbers::Visa,
              :expiration_date => "05/12"
            },
            :options => {
              :submit_for_settlement => true
            },
          ).transaction

          collection = Braintree::Transaction.search do |search|
            search.id.is transaction.id
            search.submitted_for_settlement_at.between(
              Date.today - 2,
              Date.today - 1,
            )
          end

          expect(collection.maximum_size).to eq(0)

          collection = Braintree::Transaction.search do |search|
            search.id.is transaction.id
            search.submitted_for_settlement_at.between(
              Date.today - 1,
              Date.today + 1,
            )
          end

          expect(collection.maximum_size).to eq(1)
          expect(collection.first.id).to eq(transaction.id)
        end

        it "finds transactions voided in a given range" do
          transaction = Braintree::Transaction.sale!(
            :amount => Braintree::Test::TransactionAmounts::Authorize,
            :credit_card => {
              :number => Braintree::Test::CreditCardNumbers::Visa,
              :expiration_date => "05/12"
            },
          )
          transaction = Braintree::Transaction.void(transaction.id).transaction

          collection = Braintree::Transaction.search do |search|
            search.id.is transaction.id
            search.voided_at.between(
              Date.today - 2,
              Date.today - 1,
            )
          end

          expect(collection.maximum_size).to eq(0)

          collection = Braintree::Transaction.search do |search|
            search.id.is transaction.id
            search.voided_at.between(
              Date.today - 1,
              Date.today + 1,
            )
          end

          expect(collection.maximum_size).to eq(1)
          expect(collection.first.id).to eq(transaction.id)
        end
      end

      it "allows searching on multiple statuses" do
          transaction = Braintree::Transaction.sale!(
            :amount => Braintree::Test::TransactionAmounts::Authorize,
            :credit_card => {
              :number => Braintree::Test::CreditCardNumbers::Visa,
              :expiration_date => "05/12"
            },
            :options => {
              :submit_for_settlement => true
            },
          )

          collection = Braintree::Transaction.search do |search|
            search.id.is transaction.id
            search.authorized_at.between(
              Date.today - 1,
              Date.today + 1,
            )
            search.submitted_for_settlement_at.between(
              Date.today - 1,
              Date.today + 1,
            )
          end

          expect(collection.maximum_size).to be > 0
      end
    end

    #Disabling until we have a more stable CI
    xit "returns multiple results" do
      collection = Braintree::Transaction.search
      expect(collection.maximum_size).to be > 100

      transaction_ids = collection.map { |t| t.id }.uniq.compact
      expect(transaction_ids.size).to eq(collection.maximum_size)
    end

    context "text node operations" do
      before(:each) do
        @transaction = Braintree::Transaction.sale!(
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2012",
            :cardholder_name => "Tom Smith"
          },
        )
      end

      it "is" do
        collection = Braintree::Transaction.search do |search|
          search.id.is @transaction.id
          search.credit_card_cardholder_name.is "Tom Smith"
        end

        expect(collection.maximum_size).to eq(1)
        expect(collection.first.id).to eq(@transaction.id)

        collection = Braintree::Transaction.search do |search|
          search.id.is @transaction.id
          search.credit_card_cardholder_name.is "Invalid"
        end

        expect(collection.maximum_size).to eq(0)
      end

      it "is_not" do
        collection = Braintree::Transaction.search do |search|
          search.id.is @transaction.id
          search.credit_card_cardholder_name.is_not "Anybody Else"
        end

        expect(collection.maximum_size).to eq(1)
        expect(collection.first.id).to eq(@transaction.id)

        collection = Braintree::Transaction.search do |search|
          search.id.is @transaction.id
          search.credit_card_cardholder_name.is_not "Tom Smith"
        end

        expect(collection.maximum_size).to eq(0)
      end

      it "ends_with" do
        collection = Braintree::Transaction.search do |search|
          search.id.is @transaction.id
          search.credit_card_cardholder_name.ends_with "m Smith"
        end

        expect(collection.maximum_size).to eq(1)
        expect(collection.first.id).to eq(@transaction.id)

        collection = Braintree::Transaction.search do |search|
          search.id.is @transaction.id
          search.credit_card_cardholder_name.ends_with "Tom S"
        end

        expect(collection.maximum_size).to eq(0)
      end

      it "starts_with" do
        collection = Braintree::Transaction.search do |search|
          search.id.is @transaction.id
          search.credit_card_cardholder_name.starts_with "Tom S"
        end

        expect(collection.maximum_size).to eq(1)
        expect(collection.first.id).to eq(@transaction.id)

        collection = Braintree::Transaction.search do |search|
          search.id.is @transaction.id
          search.credit_card_cardholder_name.starts_with "m Smith"
        end

        expect(collection.maximum_size).to eq(0)
      end

      it "contains" do
        collection = Braintree::Transaction.search do |search|
          search.id.is @transaction.id
          search.credit_card_cardholder_name.contains "m Sm"
        end

        expect(collection.maximum_size).to eq(1)
        expect(collection.first.id).to eq(@transaction.id)

        collection = Braintree::Transaction.search do |search|
          search.id.is @transaction.id
          search.credit_card_cardholder_name.contains "Anybody Else"
        end

        expect(collection.maximum_size).to eq(0)
      end
    end

    context "when the search times out" do
      it "raises a UnexpectedError" do
        expect {
          Braintree::Transaction.search do |search|
            search.amount.is(-10)
          end
        }.to raise_error(Braintree::UnexpectedError)
      end
    end

    it "searches by payment instrument type meta checkout" do
      meta_checkout_card_transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :options => {
          :submit_for_settlement => true
        },
        :payment_method_nonce => Braintree::Test::Nonce::MetaCheckoutCard,
      )

      meta_checkout_token_transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :options => {
          :submit_for_settlement => true
        },
        :payment_method_nonce => Braintree::Test::Nonce::MetaCheckoutToken,
      )

      collection = Braintree::Transaction.search do |search|
        search.payment_instrument_type.in ["MetaCheckout"]
      end

      collection.maximum_size.should == 2
      txn_ids = collection.map(&:id)
      expect(txn_ids).to include(meta_checkout_card_transaction.id)
      expect(txn_ids).to include(meta_checkout_token_transaction.id)
    end
  end

  context "pagination" do
    it "is not affected by new results on the server" do
      cardholder_name = "Tom Smith #{rand(1_000_000)}"
      5.times do |index|
        Braintree::Transaction.sale!(
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2012",
            :cardholder_name => "#{cardholder_name} #{index}"
          },
        )
      end

      collection = Braintree::Transaction.search do |search|
        search.credit_card_cardholder_name.starts_with cardholder_name
      end

      count_before_new_data = collection.instance_variable_get(:@ids).count

      new_cardholder_name = "#{cardholder_name} shouldn't be included"
      Braintree::Transaction.sale!(
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2012",
            :cardholder_name => new_cardholder_name,
          },
        )

      transactions = collection.to_a
      expect(transactions.count).to eq(count_before_new_data)

      cardholder_names = transactions.map { |transaction| transaction.credit_card_details.cardholder_name }
      expect(cardholder_names).to_not include(new_cardholder_name)
    end
  end
end
