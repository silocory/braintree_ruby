require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::AdvancedSearch do
  before(:each) do
    @credit_card = Braintree::Customer.create!(
      :credit_card => {
        :number => Braintree::Test::CreditCardNumbers::Visa,
        :expiration_date => "05/2010"
      },
    ).credit_cards[0]
  end

  context "text_fields" do
    it "is" do
      id = rand(36**8).to_s(36)
      subscription1 = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :plan_id => SpecHelper::TriallessPlan[:id],
        :id => "subscription1_#{id}",
      ).subscription

      subscription2 = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :plan_id => SpecHelper::TriallessPlan[:id],
        :id => "subscription2_#{id}",
      ).subscription

      collection = Braintree::Subscription.search do |search|
        search.id.is "subscription1_#{id}"
      end

      expect(collection).to include(subscription1)
      expect(collection).not_to include(subscription2)
    end

    # we are temporarily skipping this test until we have a more stable CI env
    xit "is_not" do
      id = rand(36**8).to_s(36)
      subscription1 = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :plan_id => SpecHelper::TriallessPlan[:id],
        :price => "11",
        :id => "subscription1_#{id}",
      ).subscription

      subscription2 = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :plan_id => SpecHelper::TriallessPlan[:id],
        :price => "11",
        :id => "subscription2_#{id}",
      ).subscription

      collection = Braintree::Subscription.search do |search|
        search.id.is_not "subscription1_#{id}"
        search.price.is "11"
      end

      expect(collection).not_to include(subscription1)
      expect(collection).to include(subscription2)
    end

    it "starts_with" do
      id = rand(36**8).to_s(36)
      subscription1 = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :plan_id => SpecHelper::TriallessPlan[:id],
        :id => "subscription1_#{id}",
      ).subscription

      subscription2 = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :plan_id => SpecHelper::TriallessPlan[:id],
        :id => "subscription2_#{id}",
      ).subscription

      collection = Braintree::Subscription.search do |search|
        search.id.starts_with "subscription1_"
      end

      expect(collection).to include(subscription1)
      expect(collection).not_to include(subscription2)
    end

    # we are temporarily skipping this test until we have a more stable CI env
    xit "ends_with" do
      id = rand(36**8).to_s(36)
      subscription1 = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :plan_id => SpecHelper::TriallessPlan[:id],
        :id => "subscription1_#{id}",
      ).subscription

      subscription2 = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :plan_id => SpecHelper::TriallessPlan[:id],
        :id => "subscription2_#{id}",
      ).subscription

      collection = Braintree::Subscription.search do |search|
        search.id.ends_with "1_#{id}"
      end

      expect(collection).to include(subscription1)
      expect(collection).not_to include(subscription2)
    end

    it "contains" do
      id = rand(36**8).to_s(36)
      subscription1 = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :plan_id => SpecHelper::TriallessPlan[:id],
        :id => "subscription1_#{id}",
      ).subscription

      subscription2 = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :plan_id => SpecHelper::TriallessPlan[:id],
        :id => "subscription2_#{id}",
      ).subscription

      collection = Braintree::Subscription.search do |search|
        search.id.contains "scription1_"
      end

      expect(collection).to include(subscription1)
      expect(collection).not_to include(subscription2)
    end
  end

  context "multiple_value_field" do
    context "in" do
      it "matches all values if none are specified" do
        subscription1 = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TriallessPlan[:id],
          :price => "12",
        ).subscription

        subscription2 = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TriallessPlan[:id],
          :price => "12",
        ).subscription

        Braintree::Subscription.cancel(subscription2.id)

        collection = Braintree::Subscription.search do |search|
          search.plan_id.is SpecHelper::TriallessPlan[:id]
          search.price.is "12"
        end

        expect(collection).to include(subscription1)
        expect(collection).to include(subscription2)
      end

      it "returns only matching results" do
        subscription1 = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TriallessPlan[:id],
          :price => "13",
        ).subscription

        subscription2 = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TriallessPlan[:id],
          :price => "13",
        ).subscription

        Braintree::Subscription.cancel(subscription2.id)

        collection = Braintree::Subscription.search do |search|
          search.status.in Braintree::Subscription::Status::Active
          search.price.is "13"
        end

        expect(collection).to include(subscription1)
        expect(collection).not_to include(subscription2)
      end

      # ignore until more stable CI
      xit "returns only matching results given an argument list" do
        subscription1 = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TriallessPlan[:id],
          :price => "14",
        ).subscription

        subscription2 = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TriallessPlan[:id],
          :price => "14",
        ).subscription

        Braintree::Subscription.cancel(subscription2.id)

        collection = Braintree::Subscription.search do |search|
          search.status.in Braintree::Subscription::Status::Active, Braintree::Subscription::Status::Canceled
          search.price.is "14"
        end

        expect(collection).to include(subscription1)
        expect(collection).to include(subscription2)
      end

      describe "is" do
        it "accepts single argument" do
          subscription1 = Braintree::Subscription.create(
            :payment_method_token => @credit_card.token,
            :plan_id => SpecHelper::TriallessPlan[:id],
            :price => "15",
          ).subscription

          subscription2 = Braintree::Subscription.create(
            :payment_method_token => @credit_card.token,
            :plan_id => SpecHelper::TriallessPlan[:id],
            :price => "15",
          ).subscription

          Braintree::Subscription.cancel(subscription2.id)

          collection = Braintree::Subscription.search do |search|
            search.status.is Braintree::Subscription::Status::Active
            search.price.is "15"
          end

          expect(collection).to include(subscription1)
          expect(collection).not_to include(subscription2)
        end
      end

      it "returns only matching results given an array" do
        subscription1 = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TriallessPlan[:id],
          :price => "16",
        ).subscription

        subscription2 = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TriallessPlan[:id],
          :price => "16",
        ).subscription

        Braintree::Subscription.cancel(subscription2.id)

        collection = Braintree::Subscription.search do |search|
          search.status.in [Braintree::Subscription::Status::Active, Braintree::Subscription::Status::Canceled]
          search.price.is "16"
        end

        expect(collection).to include(subscription1)
        expect(collection).to include(subscription2)
      end

      it "returns expired subscriptions" do
        collection = Braintree::Subscription.search do |search|
          search.status.in [Braintree::Subscription::Status::Expired]
        end

        expect(collection.maximum_size).to be > 0
        collection.all? { |subscription| expect(subscription.status).to eq(Braintree::Subscription::Status::Expired) }
      end
    end
  end

  context "multiple_value_or_text_field" do
    describe "in" do
      xit "works for the in operator(temporarily disabling until more stable CI)" do
        Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TriallessPlan[:id],
          :price => "17",
        ).subscription

        Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TrialPlan[:id],
          :price => "17",
        ).subscription

        Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::AddOnDiscountPlan[:id],
          :price => "17",
        ).subscription

        plan_ids = [SpecHelper::TriallessPlan[:id], SpecHelper::TrialPlan[:id]]
        collection = Braintree::Subscription.search do |search|
          search.plan_id.in plan_ids
          search.price.is "17"
        end

        expect(collection.maximum_size).to be > 0
        collection.all? { |subscription| plan_ids.include?(subscription.plan_id) }
      end
    end

    context "a search with no matches" do
      it "works" do
        collection = Braintree::Subscription.search do |search|
          search.plan_id.is "not_a_real_plan_id"
        end

        expect(collection.maximum_size).to eq(0)
      end
    end

    describe "is" do
      it "returns resource collection with matching results" do
        trialless_subscription = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TriallessPlan[:id],
          :price => "18",
        ).subscription

        trial_subscription = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TrialPlan[:id],
          :price => "18",
        ).subscription

        collection = Braintree::Subscription.search do |search|
          search.plan_id.is SpecHelper::TriallessPlan[:id]
          search.price.is "18"
        end

        expect(collection).to include(trialless_subscription)
        expect(collection).not_to include(trial_subscription)
      end
    end

    describe "is_not" do
      it "returns resource collection without matching results" do
        trialless_subscription = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TriallessPlan[:id],
          :price => "19",
        ).subscription

        trial_subscription = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TrialPlan[:id],
          :price => "19",
        ).subscription

        collection = Braintree::Subscription.search do |search|
          search.plan_id.is_not SpecHelper::TriallessPlan[:id]
          search.price.is "19"
        end

        expect(collection).not_to include(trialless_subscription)
        expect(collection).to include(trial_subscription)
      end
    end

    describe "ends_with" do
      it "returns resource collection with matching results" do
        trialless_subscription = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TriallessPlan[:id],
          :price => "20",
        ).subscription

        trial_subscription = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TrialPlan[:id],
          :price => "20",
        ).subscription

        collection = Braintree::Subscription.search do |search|
          search.plan_id.ends_with "trial_plan"
          search.price.is "20"
        end

        expect(collection).to include(trial_subscription)
        expect(collection).not_to include(trialless_subscription)
      end
    end

    describe "starts_with" do
      it "returns resource collection with matching results" do
        trialless_subscription = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TriallessPlan[:id],
          :price => "21",
        ).subscription

        trial_subscription = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TrialPlan[:id],
          :price => "21",
        ).subscription

        collection = Braintree::Subscription.search do |search|
          search.plan_id.starts_with "integration_trial_p"
          search.price.is "21"
        end

        expect(collection).to include(trial_subscription)
        expect(collection).not_to include(trialless_subscription)
      end
    end

    describe "contains" do
      it "returns resource collection with matching results" do
        trialless_subscription = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TriallessPlan[:id],
          :price => "22",
        ).subscription

        trial_subscription = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TrialPlan[:id],
          :price => "22",
        ).subscription

        collection = Braintree::Subscription.search do |search|
          search.plan_id.contains "trial_p"
          search.price.is "22"
        end

        expect(collection).to include(trial_subscription)
        expect(collection).not_to include(trialless_subscription)
      end
    end
  end

  context "range_field" do
    it "is" do
      subscription_500 = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :plan_id => SpecHelper::TriallessPlan[:id],
        :price => "5.00",
      ).subscription

      subscription_501 = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :plan_id => SpecHelper::TrialPlan[:id],
        :price => "5.01",
      ).subscription

      collection = Braintree::Subscription.search do |search|
        search.price.is "5.00"
      end

      expect(collection).to include(subscription_500)
      expect(collection).not_to include(subscription_501)
    end

    it "<=" do
      subscription_499 = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :plan_id => SpecHelper::TrialPlan[:id],
        :price => "4.99",
      ).subscription

      subscription_500 = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :plan_id => SpecHelper::TriallessPlan[:id],
        :price => "5.00",
      ).subscription

      subscription_501 = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :plan_id => SpecHelper::TrialPlan[:id],
        :price => "5.01",
      ).subscription

      collection = Braintree::Subscription.search do |search|
        search.price <= "5.00"
      end

      expect(collection).to include(subscription_499)
      expect(collection).to include(subscription_500)
      expect(collection).not_to include(subscription_501)
    end

    it ">=" do
      subscription_499 = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :plan_id => SpecHelper::TrialPlan[:id],
        :price => "999.99",
      ).subscription

      subscription_500 = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :plan_id => SpecHelper::TriallessPlan[:id],
        :price => "1000.00",
      ).subscription

      subscription_501 = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :plan_id => SpecHelper::TrialPlan[:id],
        :price => "1000.01",
      ).subscription

      collection = Braintree::Subscription.search do |search|
        search.price >= "1000.00"
      end

      expect(collection).not_to include(subscription_499)
      expect(collection).to include(subscription_500)
      expect(collection).to include(subscription_501)
    end

    it "between" do
      subscription_499 = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :plan_id => SpecHelper::TrialPlan[:id],
        :price => "4.99",
      ).subscription

      subscription_500 = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :plan_id => SpecHelper::TriallessPlan[:id],
        :price => "5.00",
      ).subscription

      subscription_502 = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :plan_id => SpecHelper::TrialPlan[:id],
        :price => "5.02",
      ).subscription

      collection = Braintree::Subscription.search do |search|
        search.price.between "4.99", "5.01"
      end

      expect(collection).to include(subscription_499)
      expect(collection).to include(subscription_500)
      expect(collection).not_to include(subscription_502)
    end
  end
end
