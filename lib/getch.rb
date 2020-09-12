require_relative 'getch/options'
require_relative 'getch/disk'

module Getch

  DEFAULT_OPTIONS = {
    language: 'en_US',
    location: 'US/Eastern',
    keyboard: 'us',
    disk: 'sda',
    fs: 'ext4',
    username: nil
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
    puts
    print "Partition and format disk #{disk}, this will erase all data, continue? (n,y) "
    case gets.chomp
    when /^y|^Y/
      disk = Getch::Disk.new(disk, fs)
      disk.cleaning
      disk.partition
      disk.format
    else
      return
    end
  end

  def self.main(argv)
    options = Options.new(DEFAULT_OPTIONS, argv)
    resume_options(options)
    format(options.disk, options.fs)
  end
end
