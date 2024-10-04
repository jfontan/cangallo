
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

class Cangallo

  class Qcow2
    attr_reader :path

    def self.qemu_img=(path)
      @@qemu_img = path
    end

    def self.qemu_img
      @@qemu_img ||= "qemu-img"
    end

    def self.qemu_img_version
      text = execute("--version")

      m = text.match(/^qemu-img version (\d+\.\d+\.\d+)/)

      if m
        m[1]
      else
        nil
      end
    end

    def self.qemu_img_backing_file_parameter(path)
      q = Qcow2.new(path)
      format = q.info['format']
      "-o backing_file=#{path},backing_fmt=#{format}"
    end

    def initialize(path=nil)
      @path=path
    end

    def info
      res = execute :info, '--output=json', @path

      JSON.parse res
    end

    def compress(destination = nil, parent = nil)
      copy(destination, :parent => parent, :compress => true)
    end

    def convert(destination, options = {})
      command = [:convert]
      command << '-c' if options[:compress]
      command << "-O #{options[:format]}" if options[:format]
      command += [@path, destination]

      execute(*command)
    end

    def copy(destination = nil, options = {})
      ops = {
        :parent => nil,
        :compress => true,
        :only_copy => false
      }.merge(options)

      parent = ops[:parent]

      new_path = destination || @path + '.compressed'

      command = [:convert, "-p", "-O qcow2"]
      command << '-c' if ops[:compress]
      command << Qcow2.qemu_img_backing_file_parameter(parent) if parent
      command += [@path, new_path]

      if ops[:only_copy]
        FileUtils.cp(@path, new_path)
      else
        execute(*command)
      end

      # pp command
      # system(*command)

      if !destination
        begin
          File.rm @path
          File.mv new_path, @path
        ensure
          File.rm new_path if File.exist? new_path
        end
      else
        @path = new_path
      end
    end

    def sparsify(destination)
      parent = info['backing_file']
      parent_options = ''

      parent_options = "-o backing_file=#{parent}" if parent

      command = "TMPDIR=#{File.dirname(destination)} virt-sparsify #{parent_options} #{@path} #{destination}"
      status, stdout, stderr = systemu command
    end

    def sha(ver = 256)
      command = "guestfish --progress-bars --ro -a #{@path} " <<
                "run : checksum-device sha#{ver} /dev/sda"
      %x{#{command}}.strip
    end

    def sha1
      sha(1)
    end

    def sha256
      sha(256)
    end

    def rebase(new_base)
      execute :rebase, '-u', "-b #{new_base}", @path
    end

    def execute(command, *params)
      self.class.execute(command, params)
    end

    def self.execute(command, *params)
      command = "#{qemu_img} #{command} #{params.join(' ')}"
      STDERR.puts command

      status, stdout, stderr = systemu command

      if status.success?
        stdout
      else
        raise stderr
      end
    end

    def self.create_from_base(origin, destination, size=nil)
      create(destination, origin, size)
    end

    def self.create(image, parent=nil, size=nil)
      cmd = [:create, '-f qcow2']
      cmd << Qcow2.qemu_img_backing_file_parameter(parent) if parent
      cmd << image
      cmd << size if size
      execute(*cmd)
    end
  end

end
