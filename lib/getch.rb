# frozen_string_literal: true

require 'clean'
require_relative 'getch/helpers'
require_relative 'getch/options'
require_relative 'getch/states'
require_relative 'getch/gentoo'
require_relative 'getch/void'
require_relative 'getch/filesystem'
require_relative 'getch/command'
require_relative 'getch/log'
require_relative 'getch/config'
require_relative 'getch/guard'
require_relative 'getch/version'

module Getch

  OPTIONS = {
    language: 'en_US',
    zoneinfo: 'US/Eastern',
    keymap: 'us',
    disk: false,
    fs: 'ext4',
    username: false,
    os: 'gentoo',
    boot_disk: false,
    cache_disk: false,
    home_disk: false,
    encrypt: false,
    verbose: false,
    mountpoint: '/mnt/getch',
    musl: false
  }

  STATES = {
    partition: false,
    format: false,
    mount: false,
    gentoo_base: false,
    gentoo_config: false,
    gentoo_update: false,
    gentoo_bootloader: false,
    gentoo_kernel: false
  }

  MOUNTPOINT = '/mnt/getch'

  DEFAULT_FS = {
    true => {
      ext4: FileSystem::Ext4::Encrypt,
      lvm: FileSystem::Lvm::Encrypt,
      zfs: FileSystem::Zfs::Encrypt
    },
    false => {
      ext4: FileSystem::Ext4,
      lvm: FileSystem::Lvm,
      zfs: FileSystem::Zfs,
    }
  }.freeze

  def self.select_fs
    encrypt = OPTIONS[:encrypt]
    fs_sym = OPTIONS[:fs].to_sym
    DEFAULT_FS[encrypt][fs_sym]
  end

  class Main
    def initialize(argv)
      argv[:cli]
      @class_fs = Getch::select_fs
      @log = Log.new
      Getch::States.new # Update States
    end

    def resume
      raise 'No disk, use at least getch with -d DISK' unless OPTIONS[:disk]

      puts "\nBuild " + OPTIONS[:os].capitalize + " Linux with the following args:\n"
      puts
      puts "\tLang: #{OPTIONS[:language]}"
      puts "\tZoneinfo: #{OPTIONS[:zoneinfo]}"
      puts "\tKeymap: #{OPTIONS[:keymap]}"
      puts "\tDisk: #{OPTIONS[:disk]}"
      puts "\tFilesystem: #{OPTIONS[:fs]}"
      puts "\tUsername: #{OPTIONS[:username]}"
      puts "\tEncrypt: #{OPTIONS[:encrypt]}"
      puts
      puts "\tseparate-boot disk: #{OPTIONS[:boot_disk]}"
      puts "\tseparate-cache disk: #{OPTIONS[:cache_disk]}"
      puts "\tseparate-home disk: #{OPTIONS[:home_disk]}"
      puts
      print 'Continue? (y,N) '
      case gets.chomp
      when /^y|^Y/
        return
      else
        exit
      end
    end

    def partition
      return if STATES[:partition]

      puts
      print "Partition and format disk #{OPTIONS[:disk]}, this will erase all data, continue? (y,N) "
      case gets.chomp
      when /^y|^Y/
        Clean.new(OPTIONS).x
        @log.info "Partition start\n"
        @class_fs::Partition.new
      else
        exit
      end
    end

    def format
      return if STATES[:format]

      @class_fs::Format.new
    end

    def mount
      return if STATES[:mount]

      @class_fs::Mount.new.run
    end

    def install
      case OPTIONS[:os]
      when 'gentoo'
        install_gentoo
      when 'void'
        install_void
      else
        raise "Options #{OPTIONS[:os]} not supported...."
      end
    end

    def install_gentoo
      gentoo = Getch::Gentoo::Main.new
      gentoo.stage3
      gentoo.config
      gentoo.chroot
      gentoo.bootloader
      gentoo.kernel
      gentoo.boot
    end

    def install_void
      void = Getch::Void::Main.new
      void.root_fs
      void.config
      void.chroot
      void.boot
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
