#
# Copyright 2021- Calyptia Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "fluent/plugin/filter"
require "fluent/event"
require "fluent/time"
require "cmetrics"
require "time"

module Fluent
  module Plugin
    class CMetricsParserFilter < Fluent::Plugin::Filter
      Fluent::Plugin.register_filter("cmetrics_parser", self)

      helpers :record_accessor

      desc "cmetrics metric key"
      config_param :cmetrics_metric_key, :string, default: "cmetrics"
      desc "cmetrics labels key"
      config_param :cmetrics_labels_key, :string, default: "labels"
      desc "hostname key"
      config_param :host_key, :string, default: "host"
      desc "format to Splunk metrics"
      config_param :format_to_splunk_metric, :bool, default: false
      desc "dimensions key"
      config_param :dimensions_key, :string, default: nil

      def configure(conf)
        super
        @serde = ::CMetrics::Serde.new
        @record_accessor = record_accessor_create(@cmetrics_metric_key)
        @labels_accessor = record_accessor_create(@cmetrics_labels_key)
        @hostname_accessor = record_accessor_create(@host_key)
      end

      def format_to_splunk_style_with_dims(inner)
        subsystem = inner.delete("subsystem")
        # labels will be treated as dimensions.
        dimensions = Hash.new(0)
        if labels = @labels_accessor.call(inner)
          labels.map {|k,v|
            dimensions[k] = v
          }
        end
        name = inner.delete("name")
        return [subsystem, name].compact.reject{|e| e.empty?}.join("."), dimensions
      end

      def filter_stream(tag, es)
        new_es = Fluent::MultiEventStream.new
        es.each do |time, record|
          data = @record_accessor.call(record)
          hostname = @hostname_accessor.call(record)
          @serde.feed_each(data) do |cmetrics|
            metrics = cmetrics.metrics
            metrics.each do |metric|
              next if metric.empty?

              metric.each do |inner|
                if @format_to_splunk_metric
                  inner["name"], dims = format_to_splunk_style_with_dims(inner)
                  if @dimensions_key
                    inner[@dimensions_key] = dims
                  else
                    inner.merge!(dims)
                  end
                end
                if hostname
                  inner[@host_key] = hostname
                end
                time = Time.at(inner.delete("timestamp"))
                new_es.add(Fluent::EventTime.new(time.to_i, time.nsec), inner)
              end
            end
          end
        end
        new_es
      end
    end
  end
end
