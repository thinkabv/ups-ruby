require "spec_helper"
require "support/shipping_options"

describe UPS::Connection do
  describe "when setting test mode" do
    subject { UPS::Connection.new(test_mode: true) }

    it "should set the uri to the test url" do
      expect(subject.url).must_equal UPS::Connection::TEST_URL
    end
  end

  describe "when setting live mode" do
    subject { UPS::Connection.new }

    it "should set the uri to the live url" do
      expect(subject.url).must_equal UPS::Connection::LIVE_URL
    end
  end

  describe "when trying to get access token before authorization" do
    subject { UPS::Connection.new }

    it "should raise an authorization error" do
      assert_raises UPS::Exceptions::AuthorizationError do
        subject.get_access_token
      end
    end
  end
end
