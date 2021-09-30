# fluent-plugin-cmetrics

[Fluentd](https://fluentd.org/) plugin for cmetrics format handling.

## Installation

### RubyGems

```
$ gem install fluent-plugin-cmetrics
```

### Bundler

Add following line to your Gemfile:

```ruby
gem "fluent-plugin-cmetrics"
```

And then execute:

```
$ bundle
```

## Plugin helpers

* [record_accessor](https://docs.fluentd.org/v/1.0/plugin-helper-overview/api-plugin-helper-record_accessor)

* See also: [Filter Plugin Overview](https://docs.fluentd.org/v/1.0/filter#overview)

## Fluent::Plugin::CMetricsParserFilter

### cmetrics_metric_key (string) (optional)

cmetrics metric key

Default value: `cmetrics`.

### cmetrics_labels_key (string) (optional)

cmetrics labels key

Default value: `labels`.

### host_key (string) (optional)

hostname key

Default value: `host`.

### format_to_splunk_metric (bool) (optional)

format to Splunk metrics

### dimensions_key (string) (optional)

dimensions key

## Fluent::Plugin::CMetricsSplunkMetricPayloadFormatter

### cmetrics_name_key (string) (optional)

cmetrics metrics name key

Default value: `name`.

### cmetrics_value_key (string) (optional)

cmetrics metrics value key

Default value: `value`.

### cmetrics_dims_key (string) (optional)

cmetrics metrics dimensions key

Default value: `dims`.

### host_key (string) (optional)

Specify host key

Default value: `host`.

### index (string) (optional)

Specify splunk index name

### source (string) (optional)

Specify splunk source name

### sourcetype (string) (optional)

Specify splunk sourcetype name

## Copyright

* Copyright(c) 2021- Calyptia Inc.
* Current manitainer: Hiroshi Hatake <hatake@calyptia.com>
* License
  * Apache License, Version 2.0
