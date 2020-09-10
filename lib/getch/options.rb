require 'optparse'

module Getch
  class Options
    attr_reader :language, :zoneinfo, :keyboard, :disk, :fs, :username

    def initialize(argv)
      @language = ""
      @zoneinfo = ""
      @keyboard = ""
      @disk = ""
      @fs = ""
      @username = ""
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
        opts.on("-d", "--disk DISK", "Name for disk (sda,sdb)") do |disk|
          @disk = disk
        end
        opts.on("-f", "--format FS", "Default use ext4") do |fs|
          @fs = fs
        end
        opts.on("-u", "--username USERNAME", "Initialize /home/username") do |user|
          @username = username
        end
        opts.on("-h", "--help", "Display this") do
          puts opts
          exit
        end

        begin
          argv = ["-h"] if argv.empty?
          opts.parse!(argv)
        rescue OptionParser::ParseError => e
          STDERR.puts e.message, "\n", opts
          exit(-1)
        end
      end
    end
  end
end
