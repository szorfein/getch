# frozen_string_literal: true

module Getch
  module FileSystem
    class Partition
      def initialize
        @log = Getch::Log.new
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

      private

      def exec(*cmd)
        if Getch::OPTIONS[:encrypt]
          Helpers.sys(cmd)
        else
          Getch::Command.new(cmd)
        end
      end
    end
  end
end
