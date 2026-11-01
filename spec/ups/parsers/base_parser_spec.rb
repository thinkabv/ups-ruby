require "spec_helper"

describe UPS::Parsers::BaseParser do
  let(:parser_class) do
    Class.new(UPS::Parsers::BaseParser) do
      private

      def root_response
        parsed_response[:ExampleResponse]
      end
    end
  end

  def parse(body)
    parser_class.new(body.to_json)
  end

  it "is successful on status 1" do
    parser = parse(ExampleResponse: {Response: {ResponseStatus: {Code: "1", Description: "Success"}}})

    expect(parser.success?).must_equal true
    expect(parser.status_description).must_equal "Success"
    expect(parser.errors).must_be_empty
  end

  it "reports every alert on a failed status" do
    parser = parse(ExampleResponse: {Response: {
      ResponseStatus: {Code: "0", Description: "Failure"},
      Alert: [{Code: "111100", Description: "Invalid package weight."}, {Code: "111210", Description: "Missing destination."}]
    }})

    expect(parser.success?).must_equal false
    expect(parser.errors.map(&:code)).must_equal %w[111100 111210]
    expect(parser.error_description).must_equal "Invalid package weight.; Missing destination."
  end

  it "reads the older StatusCode spelling too" do
    parser = parse(ExampleResponse: {Response: {ResponseStatus: {StatusCode: "0", StatusDescription: "Failure"}}})

    expect(parser.success?).must_equal false
    expect(parser.status_description).must_equal "Failure"
  end

  it "reports HTTP-level errors" do
    parser = parse(response: {errors: [{code: "250003", message: "Invalid Access License number"}]})

    expect(parser.success?).must_equal false
    expect(parser.errors.first.code).must_equal "250003"
    expect(parser.error_description).must_equal "Invalid Access License number"
  end

  it "treats a response without a status element as successful" do
    expect(parse(ExampleResponse: {}).success?).must_equal true
  end

  it "raises on a body that is not JSON" do
    assert_raises(UPS::Exceptions::ResponseError) { parser_class.new("<html>Service Unavailable</html>").success? }
  end
end
