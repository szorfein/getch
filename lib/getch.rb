require_relative 'getch/options'
require_relative 'getch/disk'
require_relative 'getch/states'

module Getch

  DEFAULT_OPTIONS = {
    language: 'en_US',
    location: 'US/Eastern',
    keyboard: 'us',
    disk: 'sda',
    fs: 'ext4',
    username: nil
  }

  STATES = {
    :partition => false,
    :format => false,
    :mount => false,
    :gentoo_base => false
  }

  def self.resume_options(opts)
    puts "\nBuild Gentoo with the following args:\n"
    puts "lang: #{opts.language}"
    puts "zoneinfo: #{opts.zoneinfo}"
    puts "keyboard: #{opts.keyboard}"
    puts "disk: #{opts.disk}"
    puts "fs: #{opts.fs}"
    puts "username: #{opts.username}"
    puts
    print "Continue? (n,y) "
    case gets.chomp
    when /^y|^Y/
      return
    else
      exit 1
    end
  end

  def self.format(disk, fs)
    return if STATES[:format] and STATES[:partition]
    puts
    print "Partition and format disk #{disk}, this will erase all data, continue? (n,y) "
    case gets.chomp
    when /^y|^Y/
      disk = Getch::Disk.new(disk, fs)
      disk.cleaning
      disk.partition
      disk.format
    else
      exit 1
    end
  end

  def self.main(argv)
    options = Options.new(DEFAULT_OPTIONS, argv)
    resume_options(options)
    Getch::States.new() # Update States
    format(options.disk, options.fs)
  end
end
