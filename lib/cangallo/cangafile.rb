
# vim:tabstop=2:sw=2:et:

# Copyright 2016, Javier Fontán Muiños <jfontan@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'json'
require 'systemu'
require 'tempfile'
require 'fileutils'
require 'yaml'

class Cangallo

  class Cangafile
    attr_accessor :data

    ACTIONS = {
      "copy" => {
        "action" => lambda do |input|
          add_head "copy-in #{input.gsub(" ", ":")}"
        end
      },

      "run" => {
        "type" => [Array, String],
        "action" => lambda do |input|
          if input.class == String
            commands = input.split("\n").reject {|l| l.empty? }
          else
            commands = input
          end

          commands.each do |cmd|
            add_head "run-command #{cmd}"
          end
        end
      },

      "change" => {
        "type" => Hash,
        "action" => lambda do |input|
          regexp = input["regexp"].gsub("/", "\\/")
          text = input["text"]
          file = input["file"]
          add_head "run-command sed -i 's/#{regexp}/#{text}/g' #{file}"
        end
      },

      "delete" => {
        "action" => lambda do |input|
          add_head "delete #{input}"
        end
      },

      "password" => {
        "type" => Hash,
        "action" => lambda do |input|
          if input["disabled"]
            password = "disabled"
          else
            password = "password:#{input["password"]}"
          end

          add_parameter "--password '#{input["user"]}:#{password}'"
        end
      }
    }

    def initialize(file)
      text = File.read(file)
      @data = YAML.load(text)

      @params = []
      @head = []
      @tail = []

      if !@data["tasks"] || @data["tasks"].class != Array
        raise "No tasks defined or it's not an array"
      end

      @tasks = @data["tasks"]
    end

    def render
      @tasks.each do |task|
        raise %Q{Task "#{task.inspect}" malformed} if task.class != Hash

        action_name = task.keys.first
        action_data = task[action_name]

        if !ACTIONS.keys.include?(action_name)
          raise %Q{Invalid action "#{action_name}"}
        end

        action = ACTIONS[action_name]

        if action["type"]
          type = [action["type"]].flatten
        else
          type = [String]
        end

        # Check action value type
        task_type = action_data.class
        if !type.include?(task_type)
          raise %Q{Action parameters for "#{action_name}" must be "#{type.inspect}"}
        end

        if action["action"]
          instance_exec(action_data, &action["action"])
        end
      end

      return @head + @tail, @params
    end

    def add_head(str)
      @head << str
    end

    def add_tail(str)
      @tail.unshift(str)
    end

    def add_parameter(str)
      @params << str
    end

    def file_commands
      text = ""

      if @data["files"]
        @data["files"].each do |line|
          l = line.gsub(" ", ":")
          text << "copy-in #{l}\n"
        end
      end

      return text
    end

    def run_commands
      text = ""

      if @data["run"]
        @data["run"].each do |line|
          text << "run-command #{line}\n"
        end
      end

      return text
    end

    def libguestfs_commands
      @tasks.each do |task|
        if task.class != Hash
          raise "This task is not a hash: #{task}"
        end


      end
    end

    def libguestfs_commands_old
      text = file_commands
      text << run_commands
      text
    end

    def parent
      @data["parent"]
    end
  end

end
