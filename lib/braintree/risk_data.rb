module Braintree
  class RiskData
    include BaseModule

    attr_reader :customer_device_id
    attr_reader :customer_location_zip
    attr_reader :customer_tenure
    attr_reader :decision
    attr_reader :decision_reasons
    attr_reader :device_data_captured
    attr_reader :fraud_service_provider
    attr_reader :id
    attr_reader :liability_shift
    attr_reader :transaction_risk_score

    def initialize(attributes)
      set_instance_variables_from_hash attributes unless attributes.nil?
      @liability_shift = LiabilityShift.new(attributes[:liability_shift]) if attributes[:liability_shift]
    end

    def inspect
      attr_order = [:id, :decision, :decision_reasons, :device_data_captured, :fraud_service_provider, :liability_shift, :transaction_risk_score]
      formatted_attrs = attr_order.map do |attr|
        "#{attr}: #{send(attr).inspect}"
      end
      "#<RiskData #{formatted_attrs.join(", ")}>"
    end
  end
end
