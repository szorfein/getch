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
      others
    end

    protected

    def host_only
      mkdir "#{@mountpoint}/etc/dracut.conf.d"
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

    def get_line
    end

    def others
    end
  end
end
