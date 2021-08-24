require "helper"
require "fluent/plugin/filter_cmetrics_parser.rb"

class CmetricsParserTest < Test::Unit::TestCase
  setup do
    Fluent::Test.setup
  end

  data("cpu" => ['{"namespace":"node","subsystem":"cpu","labels":{"cpu":"10","mode":"system"},"name":"seconds_total","description":"Seconds the CPUs spent in each mode.","value":13153.09}', "cpu_cpu_10_mode_system_seconds_total"],
       "filefd" => ['{"namespace":"node","subsystem":"filefd","name":"maximum","description":"File descriptor statistics: maximum.","value":9.223372036854776e+18}', "filefd_maximum"],
       "disk" => ['{"namespace":"node","subsystem":"disk","labels":{"device":"nvme0n1"},"name":"io_now","description":"The number of I/Os currently in progress.","value":0.0}', "disk_device_nvme0n1_io_now"],
       "network" => ['{"namespace":"node","subsystem":"network","labels":{"device":"eth0"},"name":"transmit_bytes_total","description":"Network device statistic bytes.","value":997193.0}', "network_device_eth0_transmit_bytes_total"],
      "none" => ['{"namespace":"node","subsystem":"","name":"load5","description":"5m load average.","value":0.94}', "load5"])
  test "#format_record_key_to_splunk_style" do |(json_str, expected_format_key)|
    json = Yajl.load(json_str)
    d = create_driver(%[format_name_key_for_splunk_metric true])
    assert_true d.instance.format_name_key_for_splunk_metric
    assert_equal expected_format_key, d.instance.format_record_key_to_splunk_style(json)
  end

  private

  def create_driver(conf)
    Fluent::Test::Driver::Filter.new(Fluent::Plugin::CMetricsParserFilter).configure(conf)
  end
end
