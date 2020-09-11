require 'optparse'

module Getch
  class Options
    attr_reader :language, :zoneinfo, :keyboard, :disk, :fs, :username

    def initialize(default, argv)
      @language = default[:language]
      @zoneinfo = default[:location]
      @keyboard = default[:keyboard]
      @disk = default[:disk]
      @fs = default[:fs]
      @username = default[:username]
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
        opts.on("-f", "--format FS", "Default use ext4") do |fs|
          @fs = fs
        end
        opts.on("-u", "--username USERNAME", "Initialize /home/username") do |user|
          @username = user
        end
        opts.on("-h", "--help", "Display this") do
          puts opts
          exit
        end
      end.parse!
    end
  end
end
