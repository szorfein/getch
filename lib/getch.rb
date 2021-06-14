require_relative 'getch/options'
require_relative 'getch/states'
require_relative 'getch/gentoo'
require_relative 'getch/filesystem'
require_relative 'getch/command'
require_relative 'getch/helpers'
require_relative 'getch/log'
require_relative 'getch/config'
require_relative 'getch/guard'

module Getch

  DEFAULT_OPTIONS = {
    language: 'en_US',
    zoneinfo: 'US/Eastern',
    keymap: 'us',
    disk: 'sda',
    fs: 'ext4',
    username: nil,
    boot_disk: nil,
    cache_disk: nil,
    home_disk: nil,
    encrypt: false,
    verbose: false
  }

  STATES = {
    :partition => false,
    :format => false,
    :mount => false,
    :gentoo_base => false,
    :gentoo_config => false,
    :gentoo_update => false,
    :gentoo_kernel => false
  }

  MOUNTPOINT = "/mnt/gentoo".freeze
  DEFAULT_FS = {
    true => {
      ext4: Getch::FileSystem::Ext4::Encrypt,
      lvm: Getch::FileSystem::Lvm::Encrypt,
      zfs: Getch::FileSystem::Zfs::Encrypt
    },
    false => {
      ext4: Getch::FileSystem::Ext4,
      lvm: Getch::FileSystem::Lvm,
      zfs: Getch::FileSystem::Zfs,
    }
  }.freeze

  def self.class_fs
    encrypt = DEFAULT_OPTIONS[:encrypt]
    fs = DEFAULT_OPTIONS[:fs].to_sym
    DEFAULT_FS[encrypt][fs]
  end

  def self.resume_options(opts)
    puts "\nBuild Gentoo with the following args:\n"
    puts "Lang: #{DEFAULT_OPTIONS[:language]}"
    puts "Zoneinfo: #{DEFAULT_OPTIONS[:zoneinfo]}"
    puts "Keymap: #{DEFAULT_OPTIONS[:keymap]}"
    puts "Disk: #{DEFAULT_OPTIONS[:disk]}"
    puts "Filesystem: #{DEFAULT_OPTIONS[:fs]}"
    puts "Username: #{DEFAULT_OPTIONS[:username]}"
    puts "Encrypt: #{DEFAULT_OPTIONS[:encrypt]}"
    puts
    puts "separate-boot disk: #{DEFAULT_OPTIONS[:boot_disk]}"
    puts "separate-cache disk: #{DEFAULT_OPTIONS[:cache_disk]}"
    puts "separate-home disk: #{DEFAULT_OPTIONS[:home_disk]}"
    puts
    print "Continue? (n,y) "
    case gets.chomp
    when /^y|^Y/
      return
    else
      exit 1
    end
  end

  def self.format(disk, fs, user)
    return if STATES[:format] and STATES[:partition]
    log = Log.new
    puts
    print "Partition and format disk #{disk}, this will erase all data, continue? (n,y) "
    case gets.chomp
    when /^y|^Y/
      log.info("Partition start")
      class_fs::Partition.new
      class_fs::Format.new
    else
      exit 1
    end
  end

  def self.init_gentoo(options)
    gentoo = Getch::Gentoo
    gentoo.stage3
    gentoo.config(options)
    gentoo.chroot(options)
    gentoo.kernel
    gentoo.boot(options)
  end

  def self.configure(options)
    config = Getch::Config.new
    config.network
  end

  def self.main(argv)
    options = Options.new(argv)
    DEFAULT_OPTIONS.freeze
    resume_options(options)
    Getch::States.new # Update States
    format(options.disk, options.fs, options.username)
    class_fs::Mount.new.run
    init_gentoo(options)
    configure(options)
  end
end
