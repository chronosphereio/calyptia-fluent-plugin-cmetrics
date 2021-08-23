require "helper"
require "fluent/plugin/filter_cmetrics_parser.rb"

class CmetricsParserTest < Test::Unit::TestCase
  setup do
    Fluent::Test.setup
  end

  test "failure" do
    flunk
  end

  private

  def create_driver(conf)
    Fluent::Test::Driver::Filter.new(Fluent::Plugin::CMetricsParserFilter).configure(conf)
  end
end
