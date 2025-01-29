module Braintree
  class LocalPaymentReversed
    include BaseModule

    attr_reader :payment_id

    def initialize(attributes)
      set_instance_variables_from_hash(attributes)
    end

    class << self
      protected :new
    end

    def self._new(*args)
      self.new(*args)
    end
  end
end
