require "helper"
require "fluent/plugin/filter_cmetrics_parser.rb"

class CmetricsParserTest < Test::Unit::TestCase
  setup do
    Fluent::Test.setup
  end

  data("cpu" => ['{"namespace":"node","subsystem":"cpu","labels":{"cpu":"10","mode":"system"},"name":"seconds_total","description":"Seconds the CPUs spent in each mode.","value":13153.09}', "cpu.id.10.mode.system.seconds_total"],
       "filefd" => ['{"namespace":"node","subsystem":"filefd","name":"maximum","description":"File descriptor statistics: maximum.","value":9.223372036854776e+18}', "filefd.maximum"],
       "disk" => ['{"namespace":"node","subsystem":"disk","labels":{"device":"nvme0n1"},"name":"io_now","description":"The number of I/Os currently in progress.","value":0.0}', "disk.device.nvme0n1.io_now"],
       "network" => ['{"namespace":"node","subsystem":"network","labels":{"device":"eth0"},"name":"transmit_bytes_total","description":"Network device statistic bytes.","value":997193.0}', "network.device.eth0.transmit_bytes_total"],
      "none" => ['{"namespace":"node","subsystem":"","name":"load5","description":"5m load average.","value":0.94}', "load5"])
  test "#format_record_key_to_splunk_style" do |(json_str, expected_format_key)|
    json = Yajl.load(json_str)
    d = create_driver(%[format_name_key_for_splunk_metric true])
    assert_true d.instance.format_name_key_for_splunk_metric
    assert_equal expected_format_key, d.instance.format_record_key_to_splunk_style(json)
  end

  sub_test_case "Actual filtering" do
    setup do
      @binary_path = File.join(File.dirname(__dir__), "fixtures", "cmetrics.bin")
      @binary = File.read(@binary_path)
    end

    test "#filter_stream" do
      d = create_driver(%[format_name_key_for_splunk_metric true])
      time = event_time("2012-01-02 13:14:15")
      record = {"cmetrics" => @binary}
      d.run(default_tag: 'test') do
        d.feed(time, record)
      end
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
