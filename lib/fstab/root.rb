# frozen_string_literal: true

require 'nito'
require_relative '../getch/log'

module Fstab
  # Generating /etc/fstab
  class Root
    include NiTo

    def initialize(devs, options)
      @log = Getch::Log.new
      @efi = devs[:efi]   ||= nil
      @boot = devs[:boot] ||= nil
      @swap = devs[:swap] ||= nil
      @root = devs[:root] ||= nil
      @home = devs[:home] ||= nil
      @fs = options[:fs]  ||= 'ext4'
      @mountpoint = options[:mountpoint] ||= '/mnt/getch'
      @conf = "#{@mountpoint}/etc/fstab"
    end

    def generate
      @log.info 'Generating fstab...'
      write_efi
      write_boot
      write_swap
      write_root
      write_home
      write_tmp
      @log.result_ok
    end

    protected

    def write_efi
      @efi || return

      uuid = gen_uuid @efi
      line = "UUID=#{uuid} /efi vfat defaults,nosuid,nodev 0 0"
      echo_a @conf, line
    end

    def write_boot
      @boot || return

      uuid = gen_uuid @boot
      line = "UUID=#{uuid} /boot #{@fs} defaults,nosuid,noexec,nodev 0 2"
      echo_a @conf, line
    end

    def write_swap
      @swap || return

      uuid = gen_uuid @swap
      line = "UUID=#{uuid} swap swap rw,noatime,discard 0 0"
      echo_a @conf, line
    end

    def write_root
      @root || return

      uuid = gen_uuid @root
      line = "UUID=#{uuid} / #{@fs} defaults 1 1"
      echo_a @conf, line
    end

    def write_home
      @home || return

      uuid = gen_uuid @home
      line = "UUID=#{uuid} /home #{@fs} defaults,nosuid,nodev 0 2"
      echo_a @conf, line
    end

    def write_tmp
      Getch::Helpers.systemd? && return

      line = 'tmpfs /tmp tmpfs defaults,nosuid,noexec,nodev 0 0'
      echo_a @conf, line
    end

    private

    def gen_uuid(dev)
      device = dev.delete_prefix('/dev/')
      Dir.glob('/dev/disk/by-uuid/*').each do |f|
        link = File.readlink(f)
        return f.delete_prefix('/dev/disk/by-uuid/') if link.match(/#{device}$/)
      end
      @log.fatal "No uuid found for #{device}"
    end
  end
end
