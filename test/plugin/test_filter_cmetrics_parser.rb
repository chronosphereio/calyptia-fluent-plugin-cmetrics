require "helper"
require "fluent/plugin/filter_cmetrics_parser.rb"
require 'socket'

class CmetricsParserTest < Test::Unit::TestCase
  setup do
    Fluent::Test.setup
  end

  data("cpu" => ['{"namespace":"node","subsystem":"cpu","labels":{"cpu":"10","mode":"system"},"name":"seconds_total","description":"Seconds the CPUs spent in each mode.","value":13153.09}', "cpu.seconds_total", {"cpu" => "10", "mode" => "system"}],
       "filefd" => ['{"namespace":"node","subsystem":"filefd","name":"maximum","description":"File descriptor statistics: maximum.","value":9.223372036854776e+18}', "filefd.maximum", {}],
       "disk" => ['{"namespace":"node","subsystem":"disk","labels":{"device":"nvme0n1"},"name":"io_now","description":"The number of I/Os currently in progress.","value":0.0}', "disk.io_now", {"device" => "nvme0n1"}],
       "network" => ['{"namespace":"node","subsystem":"network","labels":{"device":"eth0"},"name":"transmit_bytes_total","description":"Network device statistic bytes.","value":997193.0}', "network.transmit_bytes_total", {"device" => "eth0"}],
      "none" => ['{"namespace":"node","subsystem":"","name":"load5","description":"5m load average.","value":0.94}', "load5", {}])
  test "#format_record_key_to_splunk_style" do |(json_str, expected_format_key, expected_dims)|
    json = Yajl.load(json_str)
    d = create_driver(%[
      format_to_splunk_metric true
      dimensions_key dims
    ])
    assert_true d.instance.format_to_splunk_metric
    formatted_key, dims = d.instance.format_to_splunk_style_with_dims(json)
    assert_equal expected_format_key, formatted_key
    assert_equal expected_dims, dims
  end

  sub_test_case "Actual filtering" do
    setup do
      if Gem::Version.new(CMetrics::VERSION) >= Gem::Version.new("0.3")
        @binary_path = File.join(File.dirname(__dir__), "fixtures", "cmetrics_0.3.bin")
      else
        @binary_path = File.join(File.dirname(__dir__), "fixtures", "cmetrics_0.2.bin")
      end
      @binary = File.read(@binary_path)
    end

    data("with dimensions" => "dims",
         "without dimensions" => nil)
    test "#filter_stream" do |data|
      use_dimensions = data
      d = if use_dimensions
            create_driver(%[
              format_to_splunk_metric true
              dimensions_key dims
            ])
          else
            create_driver(%[
              format_to_splunk_metric true
            ])
          end
      time = event_time("2012-01-02 13:14:15")
      record = {"cmetrics" => @binary}
      d.run(default_tag: 'test') do
        d.feed(time, record)
      end
      d.filtered.map {|e| assert_equal(!!use_dimensions, e.last.has_key?("dims"))}
      d.filtered.map {|e| assert_false(e.last.has_key?("hostname"))}
      assert do
        d.filtered.size > 0
      end
    end

    data("with dimensions" => "dims",
         "without dimensions" => nil)
    test "#filter_stream with host_key" do |data|
      use_dimensions = data
      d = if use_dimensions
            create_driver(Fluent::Config::Element.new('ROOT', '', {
                                                        "format_to_splunk_metric" => true,
                                                        "dimensions_key" => "dims",
                                                      }, [
                                                        Fluent::Config::Element.new('fields', '', {"hostname" => ""}, [])
                                                      ]))
          else
            create_driver(Fluent::Config::Element.new('ROOT', '', {
                                                        "format_to_splunk_metric" => true,
                                                      }, [
                                                        Fluent::Config::Element.new('fields', '', {"hostname" => ""}, [])
                                                      ]))
          end
      time = event_time("2012-01-02 13:14:15")
      record = {"cmetrics" => @binary, "hostname" => Socket.gethostname}
      d.run(default_tag: 'test') do
        d.feed(time, record)
      end
      d.filtered.map {|e| assert_equal(!!use_dimensions, e.last.has_key?("dims"))}
      d.filtered.map {|e| assert_true(e.last.has_key?("hostname"))}
      assert do
        d.filtered.size > 0
      end
    end
  end

  private

  def create_driver(conf)
    Fluent::Test::Driver::Filter.new(Fluent::Plugin::CMetricsParserFilter).configure(conf)
  end
end
