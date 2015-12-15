require 'chef_compat/copied_from_chef'
class Chef
module ::ChefCompat
module CopiedFromChef
#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: AJ Christensen (<@aj@opscode.com>)
# Author:: Christopher Brown (<cb@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
# License:: Apache License, Version 2.0
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


class Chef < (defined?(::Chef) ? ::Chef : Object)
  class Log < (defined?(::Chef::Log) ? ::Chef::Log : Object)
    extend Mixlib::Log

    # Force initialization of the primary log device (@logger)
    init(MonoLogger.new(STDOUT))

    class Formatter < (defined?(::Chef::Log::Formatter) ? ::Chef::Log::Formatter : Object)
      def self.show_time=(*args)
        Mixlib::Log::Formatter.show_time = *args
      end
    end

    #
    # Get the location of the caller (from the recipe). Grabs the first caller
    # that is *not* in the chef gem proper (allowing us to weed out internal
    # calls and give the user a more useful perspective).
    #
    # @return [String] The location of the caller (file:line#) from caller(0..20), or nil if no non-chef caller is found.
    #
    def self.caller_location
      # Pick the first caller that is *not* part of the Chef gem, that's the
      # thing the user wrote.
      chef_gem_path = File.expand_path("../..", __FILE__)
      caller(0..20).select { |c| !c.start_with?(chef_gem_path) }.first
    end

    def self.deprecation(msg=nil, location=caller(2..2)[0], &block)
      if msg
        msg << " at #{Array(location).join("\n")}"
        msg = msg.join("") if msg.respond_to?(:join)
      end
      if Chef::Config[:treat_deprecation_warnings_as_errors]
        error(msg, &block)
        raise Chef::Exceptions::DeprecatedFeatureError.new(msg)
      else
        warn(msg, &block)
      end
    end

  end
end
end
end
end
