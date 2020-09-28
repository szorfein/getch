require 'optparse'

module Getch
  class Options
    attr_reader :language, :zoneinfo, :keyboard, :disk, :fs, :username, :encrypt, :verbose

    def initialize(argv)
      @language = DEFAULT_OPTIONS[:language]
      @zoneinfo = DEFAULT_OPTIONS[:zoneinfo]
      @keyboard = DEFAULT_OPTIONS[:keyboard]
      @disk = DEFAULT_OPTIONS[:disk]
      @fs = DEFAULT_OPTIONS[:fs]
      @username = DEFAULT_OPTIONS[:username]
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
        opts.on("-k", "--keyboard KEY", "Default is us") do |key|
          @keyboard = key
        end
        opts.on("-d", "--disk DISK", "Disk where install Gentoo (sda,sdb)") do |disk|
          @disk = disk
        end
        opts.on("-f", "--format FS", "Can be ext4, lvm. Default use ext4") do |fs|
          @fs = fs
          DEFAULT_OPTIONS[:fs] = fs # dont known why, but it should be enforce
        end
        opts.on("-u", "--username USERNAME", "Initialize /home/username") do |user|
          @username = user
        end
        opts.on("--encrypt", "Encrypt your filesystem.!! NOT YET READY !!") do
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
