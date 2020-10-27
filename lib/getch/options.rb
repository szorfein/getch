require 'optparse'

module Getch
  class Options
    attr_reader :language, :zoneinfo, :keymap, :disk, :fs, :username, :boot_disk, :swap_disk, :encrypt, :verbose

    def initialize(argv)
      @language = DEFAULT_OPTIONS[:language]
      @zoneinfo = DEFAULT_OPTIONS[:zoneinfo]
      @keymap = DEFAULT_OPTIONS[:keymap]
      @disk = DEFAULT_OPTIONS[:disk]
      @fs = DEFAULT_OPTIONS[:fs]
      @username = DEFAULT_OPTIONS[:username]
      @boot_disk = DEFAULT_OPTIONS[:boot_disk]
      @swap_disk = DEFAULT_OPTIONS[:swap_disk]
      @encrypt = DEFAULT_OPTIONS[:encrypt]
      @verbose = DEFAULT_OPTIONS[:verbose]
      parse(argv)
    end

    private

    def parse(argv)
      OptionParser.new do |opts|
        opts.on("-l", "--language LANG", "Default is en_US") do |lang|
          @language = lang
        end
        opts.on("-z", "--zoneinfo ZONE", "Default is US/Eastern") do |zone|
          @zoneinfo = zone
        end
        opts.on("-k", "--keymap KEY", "Default is us") do |key|
          @keymap = key
        end
        opts.on("-d", "--disk DISK", "Disk where install Gentoo (sda,sdb), default use #{@disk}") do |disk|
          @disk = disk
        end
        opts.on("-f", "--format FS", "Can be ext4, lvm or zfs. Default use ext4") do |fs|
          @fs = fs
          DEFAULT_OPTIONS[:fs] = fs # dont known why, but it should be enforce
        end
        opts.on("-u", "--username USERNAME", "Create a partition /home and add a new user /home/USERNAME") do |user|
          @username = user
        end
        opts.on("--separate-boot DISK", "Disk for the boot partition, default use #{@disk}") do |boot|
          @boot_disk = boot
          DEFAULT_OPTIONS[:boot_disk] = boot
        end
        opts.on("--separate-swap DISK", "Disk for the swap partition, default use #{@disk}") do |swap|
          @swap_disk = swap
          DEFAULT_OPTIONS[:swap_disk] = swap
        end
        opts.on("--encrypt", "Encrypt your system.") do
          @encrypt = true
        end
        opts.on("--verbose", "Write more messages to the standard output.") do
          @verbose = true
        end
        opts.on("-h", "--help", "Display this") do
          puts opts
          exit
        end
      end.parse!(into: DEFAULT_OPTIONS)
    end
  end
end
