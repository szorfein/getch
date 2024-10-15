# frozen_string_literal: true

require 'optparse'
require 'nito'

module Getch
  class Options
    include NiTo

    def initialize(argv)
      parse(argv)
    end

    private

    def parse(argv)
      OptionParser.new do |opts|
        opts.banner = 'Usage: getch [OPTION...] <action>'

        opts.separator "\noptions:"

        opts.on('-l', '--language LANG', 'Default is en_US') do |lang|
          OPTIONS[:language] = lang
        end

        opts.on('-t', '--timezone ZONE', 'Default is UTC') do |zone|
          OPTIONS[:timezone] = Getch::Guard.zone(zone)
        end

        opts.on('-k', '--keymap KEY', 'Default is us') do |key|
          OPTIONS[:keymap] = Getch::Guard.keymap(key)
        end

        opts.on('-d', '--disk DISK',
                'Root Disk where install the system (sda,sdb)') do |disk|
          OPTIONS[:disk] = Getch::Guard.disk(disk)
        end

        opts.on('-f', '--format FS',
                'Can be ext4, zfs. Default use ext4') do |fs|
          OPTIONS[:fs] = Getch::Guard.format(fs)
        end

        opts.on('-u', '--username USERNAME',
                'Create a new user /home/USERNAME with password.') do |user|
          OPTIONS[:username] = user
        end

        opts.on('-o', '--os NAME', /gentoo|void/,
                'Install distro NAME, can be gentoo or void.') do |name|
          OPTIONS[:os] = name
        end

        opts.on('--separate-boot DISK',
                'Use a different DISK for the /boot or /efi partition.') do |boot|
          OPTIONS[:boot_disk] = Getch::Guard.disk(boot)
        end

        opts.on('--separate-cache DISK',
                'Use a different DISK for the swap partition, add ZIL/L2ARC for ZFS when set.') do |swap|
          OPTIONS[:cache_disk] = Getch::Guard.disk(swap)
        end

        opts.on('--separate-home DISK',
                'Use a different DISK for the /home partition.') do |home|
          OPTIONS[:home_disk] = Getch::Guard.disk(home)
        end

        opts.on('--boot-size SIZE', Numeric,
                'Specifie the boot size in mebibyte (mib), default use 256.') do |size|
          OPTIONS[:boot_size] = size
        end

        opts.on('--swap-size SIZE', Numeric,
                "Specifie the swap size in megabyte (mb), default use your current memory #{Getch::OPTIONS[:swap_size]}.") do |size|
          OPTIONS[:swap_size] = size
        end

        opts.on('--root-size SIZE', Numeric,
                'Specifie the root size in gigabyte (G), default use 16 (used only on lvm when --separate-home was not specified.') do |size|
          OPTIONS[:root_size] = size
        end

        opts.on('--lvm',
                'System will use LVM, do not work with ZFS.') do
          OPTIONS[:lvm] = true
        end

        opts.on('--encrypt',
                'Encrypt your system, use LUKS or native encryption for ZFS.') do
          OPTIONS[:encrypt] = true
        end

        opts.on('--musl', 'Prefer to install Musl over Glibc.') do
          OPTIONS[:musl] = true
        end

        opts.on('--binary', 'Prefer to use binary packages instead of compile them (Gentoo).') do
          OPTIONS[:binary] = true
        end

        opts.on('--verbose', 'Write more messages to the standard output.') do
          OPTIONS[:verbose] = true
        end

        opts.on('-v', '--version', 'Display the version.') do
          puts "Getch v#{VERSION}"
          exit
        end

        opts.on('-h', '--help', 'Display this') do
          puts opts
          exit
        end

        opts.separator "\n<action> is one of:"

        opts.on('--restart', 'Restart the whole installation') do
          rm '/tmp/install_gentoo.yaml'
          rm '/tmp/log_install.txt'
          rm '/tmp/getch_devs.yaml'
        end

        begin
          opts.parse!(argv)
        rescue OptionParser::ParseError => e
          warn e.message, "\n", opts
          exit 1
        end
      end
    end
  end
end
