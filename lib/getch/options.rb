require 'optparse'

module Getch
  class Options
    def initialize(argv)
      parse(argv)
    end

    private

    def parse(argv)
      OptionParser.new do |opts|
        opts.version = VERSION

        opts.on("-l", "--language LANG", "Default is en_US") do |lang|
          OPTIONS[:language] = lang
        end

        opts.on("-z", "--zoneinfo ZONE", "Default is US/Eastern") do |zone|
          OPTIONS[:zoneinfo] = Getch::Guard.zone(zone)
        end

        opts.on("-k", "--keymap KEY", "Default is us") do |key|
          OPTIONS[:keymap] = Getch::Guard.keymap(key)
        end

        opts.on("-d", "--disk DISK", "Disk where install Gentoo (sda,sdb), default use #{@disk}") do |disk|
          OPTIONS[:disk] = Getch::Guard.disk(disk)
        end

        opts.on("-f", "--format FS", "Can be ext4, lvm or zfs. Default use ext4") do |fs|
          OPTIONS[:fs] = Getch::Guard.format(fs)
        end

        opts.on("-u", "--username USERNAME", "Create a new user /home/USERNAME with password.") do |user|
          OPTIONS[:username] = user
        end

        opts.on("-o", "--os NAME", /gentoo|void/, "Instal distro NAME, can be gentoo or void.") do |name|
          OPTIONS[:os] = name
        end

        opts.on("--separate-boot DISK", "Disk for the boot/efi partition, default use #{@disk}") do |boot|
          OPTIONS[:boot_disk] = Getch::Guard.disk(boot)
        end

        opts.on("--separate-cache DISK", "Disk for the swap partition, add ZIL/L2ARC for ZFS when set, default use #{@disk}") do |swap|
          OPTIONS[:cache_disk] = Getch::Guard.disk(swap)
        end

        opts.on("--separate-home DISK", "Disk for the /home partition, default is nil") do |home|
          OPTIONS[:home_disk] = Getch::Guard.disk(home)
        end

        opts.on("--encrypt", "Encrypt your system.") do
          OPTIONS[:encrypt] = true
        end

        opts.on("--verbose", "Write more messages to the standard output.") do
          OPTIONS[:verbose] = true
        end

        opts.on("-h", "--help", "Display this") do
          puts opts
          exit
        end

        begin
          opts.parse!(argv)
        rescue OptionParser::ParseError => e
          STDERR.puts e.message, "\n", opts
          exit 1
        end
      end
    end
  end
end
