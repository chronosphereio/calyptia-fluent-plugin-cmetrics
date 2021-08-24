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

### cmetric_metric_key (string) (optional)

cmetrics metric key

Default value: `cmetrics`.

### cmetric_labels_key (string) (optional)

cmetrics labels key

Default value: `labels`.

### format_name_key_for_splunk_metric (bool) (optional)

format name key for Splunk metrics


## Copyright

* Copyright(c) 2021- Calyptia Inc.
* Current manitainer: Hiroshi Hatake <hatake@calyptia.com>
* License
  * Apache License, Version 2.0
