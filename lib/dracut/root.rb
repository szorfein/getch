# frozen_string_litteral: true

require 'nito'
require_relative '../getch/log'

module Dracut
  class Root
    include NiTo

    def initialize(devs, options)
      @log = Getch::Log.new
      @root = devs[:root] ||= nil
      @swap = devs[:swap] ||= nil
      @fs = options[:fs] ||= 'ext4'
      @mountpoint = options[:mountpoint] ||= '/mnt/getch'
    end

    def generate
      host_only
      cmdline
    end

    protected

    def host_only
      file = "#{@mountpoint}/etc/dracut.conf.d/host.conf"
      echo file, 'hostonly="yes"'
      echo_a file, 'use_fstab="yes"'
    end

    # man dracut.cmdline(7)
    def cmdline
      file = "#{@mountpoint}/etc/dracut.conf.d/cmdline.conf"
      line = get_line
      echo file, "kernel_cmdline=\"#{line}\""
    end

    private

    def get_uuid(dev)
      device = dev.delete_prefix('/dev/')
      Dir.glob('/dev/disk/by-uuid/*').each do |f|
        link = File.readlink(f)
        return f.delete_prefix('/dev/disk/by-uuid/') if link =~ /#{device}$/
      end
      @log.fatal "Dracut - no uuid found for #{dev}"
    end

    def get_line
    end
  end
end
