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
      config_param :cmetric_metric_key, :string, default: "cmetric"

      def configure(conf)
        super
        @serde = ::CMetrics::Serde.new
        @record_accessor = record_accessor_create(@cmetric_metric_key)
      end

      def filter_stream(tag, es)
        new_es = Fluent::MultiEventStream.new
        es.each do |time, record|
          data = @record_accessor.call(record)
          @serde.feed_each(data) do |cmetrics|
            metrics = cmetrics.metrics
            metrics.each do |metric|
              next if metric.empty?

              metric.each do |inner|
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
