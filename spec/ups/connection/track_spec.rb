require "spec_helper"

describe UPS::Connection do
  before { Excon.defaults[:mock] = true }
  after { Excon.stubs.clear }

  let(:stub_path) { File.expand_path("../../stubs", __dir__) }
  let(:connection) do
    UPS::Connection.new(test_mode: true).tap { |connection| connection.authorize("ACCOUNT", "CLIENT", "SECRET", true) }
  end

  describe "a delivered package" do
    before do
      Excon.stub({method: :get}, {status: 200, body: File.read("#{stub_path}/track_success.json")})
    end

    subject { connection.track "1Z12345E6692804405" }

    it "reports the latest activity" do
      expect(subject.success?).must_equal true
      expect(subject.found?).must_equal true
      expect(subject.delivered?).must_equal true
      expect(subject.as_json).must_equal(
        status_date: Date.parse("2010-06-10"),
        status_type_description: "DELIVERED",
        status_type_code: "D"
      )
    end
  end

  describe "a number UPS does not know yet" do
    before do
      Excon.stub({method: :get}, {status: 200, body: File.read("#{stub_path}/track_not_found.json")})
    end

    subject { connection.track "1Z12345E6692804405" }

    it "has no activity" do
      expect(subject.success?).must_equal true
      expect(subject.found?).must_equal false
      expect(subject.delivered?).must_equal false
      expect(subject.status_date).must_be_nil
      expect(subject.status_type_description).must_be_nil
    end
  end

  describe "without a tracking number" do
    it "raises" do
      assert_raises(UPS::Exceptions::InvalidAttributeError) { connection.track "" }
    end
  end
end
