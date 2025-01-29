module Braintree
  class DisputeSearch < AdvancedSearch
    text_fields(
      :case_number,
      :customer_id,
      :id,
      :reference_number,
      :transaction_id,
    )
    # NEXT_MAJOR_VERSION Remove this attribute
    # DEPRECATED The chargeback_protection_level attribute is deprecated in favor of protection_level
    multiple_value_field :chargeback_protection_level, :allows => Dispute::ChargebackProtectionLevel::All
    multiple_value_field :protection_level, :allows => Dispute::ProtectionLevel::All
    multiple_value_field :kind, :allows => Dispute::Kind::All
    multiple_value_field :merchant_account_id
    multiple_value_field :pre_dispute_program, :allows => Dispute::PreDisputeProgram::All
    multiple_value_field :reason, :allows => Dispute::Reason::All
    multiple_value_field :reason_code
    multiple_value_field :status, :allows => Dispute::Status::All
    multiple_value_field :transaction_source

    range_fields(
      :amount_disputed,
      :amount_won,
      :disbursement_date,
      :effective_date,
      :received_date,
      :reply_by_date,
    )
  end
end
