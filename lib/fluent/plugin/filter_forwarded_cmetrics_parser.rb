#
# Copyright 2022- Calyptia Inc.
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
require "time"

module Fluent
  module Plugin
    class ForwardedCMetricsParserFilter < Fluent::Plugin::Filter
      Fluent::Plugin.register_filter("forwarded_cmetrics_parser", self)

      helpers :record_accessor

      desc "cmetrics labels key"
      config_param :cmetrics_labels_key, :string, default: "labels"
      desc "format to Splunk metrics"
      config_param :format_to_splunk_metric, :bool, default: false
      desc "dimensions key"
      config_param :dimensions_key, :string, default: nil
      config_section :fields, init: false, multi: false,required: false do
        # Nothing here. For later purpose.
      end

      def configure(conf)
        super
        @labels_accessor = record_accessor_create(@cmetrics_labels_key)
        @fields_accessors = {}
        conf.elements(name: "fields").each do |e|
          e.each_pair{|k, _v|
            e.has_key?(k) # Suppress unused warnings.
            @fields_accessors[k] = record_accessor_create(k)
          }
        end
      end

      def parse_cmetrics_hash(record)
        cmetrics = []
        record.each do |payload|
          payload["metrics"].each do |metric|
            labels = []
            opts = metric["meta"]["opts"]
            unless metric["meta"]["labels"].empty?
              metric["meta"]["labels"].each do |k_label|
                labels << k_label
              end
            end
            metric["values"].each do |entry|
              cmetric = {
                "namespace" => opts["ns"],
                "subsystem" => opts["ss"],
                "name" => opts["name"],
                "value" => entry["value"],
                "description" => opts["desc"],
                "timestamp" => entry["ts"] / 1000000000.0
              }
              unless labels.empty?
                params = {}
                entry["labels"].each_with_index do |v_label, index|
                  label = labels[index]
                  params[label] = v_label
                end
                cmetric["labels"] = params
              end
              cmetrics << cmetric
            end
          end
        end
        cmetrics
      end

      def format_to_splunk_style_with_dims(metric)
        subsystem = metric.delete("subsystem")
        # labels will be treated as dimensions.
        dimensions = Hash.new(0)
        if labels = @labels_accessor.call(metric)
          labels.map {|k,v|
            dimensions[k] = v
          }
        end
        name = metric.delete("name")
        return [subsystem, name].compact.reject{|e| e.empty?}.join("."), dimensions
      end

      def filter_stream(tag, es)
        new_es = Fluent::MultiEventStream.new
        es.each do |time, record|
          extra_fields = {}
          cmetrics = parse_cmetrics_hash(record)
          cmetrics.each do |metric|
            next if metric.empty?

            @fields_accessors.each do |key, accessor|
              extra_fields[key] = accessor.call(metric)
            end
            if @format_to_splunk_metric
              metric["name"], dims = format_to_splunk_style_with_dims(metric)
              if @dimensions_key
                metric[@dimensions_key] = dims
              else
                metric.merge!(dims)
              end
            end
            if @fields_accessors
              metric.merge!(extra_fields)
            end
            time = Time.at(metric.delete("timestamp"))
            new_es.add(Fluent::EventTime.new(time.to_i, time.nsec), metric)
          end
        end
        new_es
      end
    end
  end
end
