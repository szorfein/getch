# frozen_string_literal: true

require_relative 'getch/helpers'
require_relative 'getch/options'
require_relative 'getch/states'
require_relative 'getch/gentoo'
require_relative 'getch/void'
require_relative 'getch/device'
require_relative 'getch/filesystem'
require_relative 'getch/tree'
require_relative 'getch/assembly'
require_relative 'getch/command'
require_relative 'getch/log'
require_relative 'getch/config'
require_relative 'getch/guard'
require_relative 'getch/version'

module Getch
  OPTIONS = {
    boot_disk: false,
    disk: false,
    cache_disk: false,
    encrypt: false,
    fs: 'ext4',
    home_disk: false,
    keymap: 'us',
    language: 'en_US',
    luks_name: 'luks',
    lvm: false,
    mountpoint: '/mnt/getch',
    musl: false,
    os: 'gentoo',
    timezone: 'UTC',
    username: false,
    verbose: false,
    vg_name: 'vg0',
    zfs_name: 'pool',
    boot_size: 260,
    swap_size: Getch::Helpers.get_memory,
    root_size: 16,
    binary: false
  }

  STATES = {
    partition: false,
    format: false,
    mount: false,
    tarball: false,
    pre_config: false,
    update: false,
    post_config: false,
    terraform: false,
    bootloader: false,
    services: false,
    finalize: false
  }

  MOUNTPOINT = '/mnt/getch'
  DEVS = {}

  class Main
    def initialize(argv)
      argv[:cli]
      @log = Log.new
      @assembly = Assembly.new
    end

    def resume
      STATES[:partition] && return

      @log.fatal 'No disk, use at least getch with -d DISK' unless OPTIONS[:disk]
      os_cap = OPTIONS[:os].capitalize

      puts "\nBuild #{os_cap} Linux with the following args:\n"
      puts
      puts "\tLang: #{OPTIONS[:language]}"
      puts "\tTimezone: #{OPTIONS[:timezone]}"
      puts "\tKeymap: #{OPTIONS[:keymap]}"
      puts "\tDisk: #{OPTIONS[:disk]}"
      puts "\tFilesystem: #{OPTIONS[:fs]}"
      puts "\tUsername: #{OPTIONS[:username]}"
      puts "\tEncrypt: #{OPTIONS[:encrypt]}"
      puts "\tMusl: #{OPTIONS[:musl]}"
      puts "\tBinary mode: #{OPTIONS[:binary]}"
      puts
      puts "\tseparate-boot disk: #{OPTIONS[:boot_disk]}"
      puts "\tseparate-cache disk: #{OPTIONS[:cache_disk]}"
      puts "\tseparate-home disk: #{OPTIONS[:home_disk]}"
      puts
      print 'Continue? (y,N) '
      case gets.chomp
      when /^y|^Y/
      else
        exit
      end
    end

    def prepare_disk
      @assembly.clean
      @assembly.partition
      @assembly.format
      @assembly.mount
    end

    def install_system
      @assembly.tarball
      @assembly.pre_config
      @assembly.update
      @assembly.post_config
    end

    def terraform
      @assembly.terraform
      @assembly.services
    end

    def bootloader
      @assembly.luks_keys
      @assembly.bootloader
    end

    def finalize
      @assembly.finalize
    end

    def configure
      config = Getch::Config::Main.new
      config.ethernet
      config.wifi
      config.dns
      config.sysctl
      config.shell
    end
  end
end
