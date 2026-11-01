require "spec_helper"

describe UPS::Connection do
  before { Excon.defaults[:mock] = true }
  after { Excon.stubs.clear }

  let(:stub_path) { File.expand_path("../stubs", __dir__) }

  describe "environments" do
    it "uses the customer integration environment in test mode" do
      expect(UPS::Connection.new(test_mode: true).url).must_equal UPS::Connection::TEST_URL
    end

    it "uses production otherwise" do
      expect(UPS::Connection.new.url).must_equal UPS::Connection::LIVE_URL
    end
  end

  describe "before authorization" do
    it "raises when asked for a token" do
      assert_raises(UPS::Exceptions::AuthorizationError) { UPS::Connection.new.access_token }
    end

    it "rejects blank credentials" do
      assert_raises(UPS::Exceptions::AuthorizationError) { UPS::Connection.new.authorize("", "", "") }
    end
  end

  describe "tokens" do
    let(:now) { [Time.utc(2026, 1, 1, 9, 0, 0)] }
    let(:connection) { UPS::Connection.new(test_mode: true, clock: -> { now.first }) }
    let(:token_requests) { [] }

    before do
      Excon.stub({method: :post, path: UPS::Connection::TOKEN_PATH}, lambda { |params|
        token_requests << params
        {status: 200, body: {access_token: "token-#{token_requests.size}", expires_in: "14399", issued_at: "1774445494559"}.to_json}
      })
      connection.authorize("ACCOUNT", "CLIENT", "SECRET")
    end

    it "requests a token on first use and reuses it" do
      expect(connection.access_token).must_equal "token-1"
      expect(connection.access_token).must_equal "token-1"
      expect(token_requests.size).must_equal 1
    end

    it "requests a new token once the previous one expired" do
      connection.access_token
      now[0] += 14399

      expect(connection.access_token).must_equal "token-2"
      expect(token_requests.size).must_equal 2
    end

    it "counts a token as expired shortly before UPS does" do
      connection.access_token
      now[0] += 14399 - UPS::Connection::TOKEN_EXPIRY_MARGIN

      expect(connection.access_token).must_equal "token-2"
    end

    it "identifies the account and client with the token request" do
      connection.access_token

      headers = token_requests.first[:headers]
      expect(headers["x-merchant-id"]).must_equal "ACCOUNT"
      expect(headers["Authorization"]).must_equal "Basic #{Base64.strict_encode64("CLIENT:SECRET")}"
      expect(token_requests.first[:body]).must_equal "grant_type=client_credentials"
    end

    it "raises when UPS refuses the token request" do
      Excon.stub({method: :post, path: UPS::Connection::TOKEN_PATH}, {status: 401, body: "{}"})

      assert_raises(UPS::Exceptions::AuthorizationError) { connection.access_token }
    end
  end

  describe "requests" do
    let(:connection) do
      UPS::Connection.new(test_mode: true, transaction_source: "my-app").tap do |connection|
        connection.authorize("ACCOUNT", "CLIENT", "SECRET", true)
      end
    end

    it "identifies the calling application and the transaction" do
      seen = nil
      Excon.stub({method: :get}, lambda { |params|
        seen = params
        {status: 200, body: File.read("#{stub_path}/track_success.json")}
      })

      connection.track("1Z12345E6692804405")

      expect(seen[:headers]["transactionSrc"]).must_equal "my-app"
      expect(seen[:headers]["transId"].length).must_equal 32
      expect(seen[:headers]["Authorization"]).must_equal "Bearer test_token"
    end

    it "raises when UPS answers with something other than an API response" do
      Excon.stub({method: :get}, {status: 502, body: "<html>Bad gateway</html>"})

      error = assert_raises(UPS::Exceptions::ResponseError) { connection.track("1Z12345E6692804405") }
      expect(error.status).must_equal 502
    end
  end
end
