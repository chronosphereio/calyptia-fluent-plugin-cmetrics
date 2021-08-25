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

require "fluent/plugin/formatter"
require 'fluent/plugin_helper/record_accessor'
require 'fluent/plugin_helper'
require "fluent/event"
require "fluent/time"
require "yajl"
require "socket"

module Fluent
  module Plugin
    class CMetricsSplunkMetricPayloadFormatter < Fluent::Plugin::Formatter
      include PluginHelper::Mixin

      Fluent::Plugin.register_formatter('cmetrics_splunk_metric_payload', self)

      helpers :record_accessor

      desc "cmetrics metrics name key"
      config_param :cmetrics_name_key, :string, default: "name"
      desc "cmetrics metrics value key"
      config_param :cmetrics_value_key, :string, default: "value"
      desc "Specify host key"
      config_param :host_key, :string, default: "host"
      desc "Specify splunk index name"
      config_param :index, :string, default: nil
      desc "Specify splunk source name"
      config_param :source, :string, default: nil
      desc "Specify splunk sourcetype name"
      config_param :sourcetype, :string, default: nil

      def initialize
        super
        @default_host = Socket.gethostname
      end

      def configure(conf)
        super

        @cmetrics_name_accessor = record_accessor_create(@cmetrics_name_key)
        @cmetrics_value_accessor = record_accessor_create(@cmetrics_value_key)
        @host_key_accessor = record_accessor_create(@host_key)
      end

      def format(tag, time, record)
        host = if host = @host_key_accessor.call(record)
                 host
               else
                 @default_host
               end
        payload = {
          host: host,
          # From the API reference
          # https://docs.splunk.com/Documentation/Splunk/latest/RESTREF/RESTinput#services.2Fcollector
          time: time.to_f.to_s,
          event: 'metric',
        }
        payload[:index] = @index if @index
        payload[:source] = @source if @source
        payload[:sourcetype] = @sourcetype if @sourcetype

        metric_fields = {
          "metric_name:#{@cmetrics_name_accessor.call(record)}" => @cmetrics_value_accessor.call(record)
        }
        payload.merge!(metric_fields)
        Yajl.dump(payload)
      end
    end
  end
end
