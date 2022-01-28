# frozen_string_literal: true

module Getch
  module FileSystem
    class Partition
      def initialize
        @log = Getch::Log.new
      end

      def gpt(dev)
        return unless dev

        disk = disk_name(dev)
        part = dev.match(/[0-9]/)
        exec 'sgdisk', "-n#{part}:1MiB:+1MiB", "-t#{part}:EF02", disk
      end

      def boot(dev)
        return unless dev

        disk = disk_name(dev)
        part = dev.match(/[0-9]/)
        if Getch::OPTIONS[:fs] == 'zfs'
          exec 'sgdisk', "-n#{part}:0:+2G", "-t#{part}:BE00", disk
        else
          exec 'sgdisk', "-n#{part}:0:+128MiB", "-t#{part}:8300", disk
        end
      end

      def efi(dev)
        return unless dev

        disk = disk_name(dev)
        part = dev.match(/[0-9]/)
        exec 'sgdisk', "-n#{part}:1M:+260M", "-t#{part}:EF00", disk
      end

      def swap(dev)
        return unless dev

        disk = disk_name(dev)
        part = dev.match(/[0-9]/)
        if Getch::OPTIONS[:cache_disk]
          exec 'sgdisk', "-n#{part}:0:0", "-t#{part}:8200", disk
        else
          mem=`awk '/MemTotal/ {print $2}' /proc/meminfo`.chomp + 'K'
          exec 'sgdisk', "-n#{part}:0:+#{mem}", "-t#{part}:8200", disk
        end
      end

      def root(dev, code)
        return unless dev

        disk = disk_name(dev)
        part = dev.match(/[0-9]/)
        exec 'sgdisk', "-n#{part}:0:0", "-t#{part}:#{code}", disk
      end

      def home(dev, code)
        return unless dev

        disk = disk_name(dev)
        part = dev.match(/[0-9]/)
        if Getch::OPTIONS[:home_disk]
          exec 'sgdisk', "-n#{part}:0:0", "-t#{part}:#{code}", disk
        end
      end

      private

      def disk_name(dev)
        dev.match(/[^0-9]+/)
      end

      def exec(*cmd)
        if Getch::OPTIONS[:encrypt]
          Helpers.sys(cmd)
        else
          Getch::Command.new(cmd).run!
        end
      end
    end
  end
end
