module Getch
  module FileSystem
    class Partition
      def initialize
      end

      def gpt(dev)
        return if ! dev
        exec("sgdisk -n1:1MiB:+1MiB -t1:EF02 /dev/#{dev}")
      end

      def boot(dev)
        return if ! dev
        exec("sgdisk -n2:0:+128MiB -t2:8300 /dev/#{dev}")
      end

      def efi(dev)
        return if ! dev
        exec("sgdisk -n1:1M:+260M -t1:EF00 /dev/#{dev}")
      end

      def swap(dev, nb = 2)
        return if ! dev
        mem=`awk '/MemTotal/ {print $2}' /proc/meminfo`.chomp + 'K'
        exec("sgdisk -n#{nb}:0:+#{mem} -t#{nb}:8200 /dev/#{dev}")
      end

      def root(nb, code, dev)
        return if ! dev
        # Reserve 18G for the system if you need a home partition
        if DEFAULT_OPTIONS[:username]
          exec("sgdisk -n#{nb}:0:+18G -t#{nb}:#{code}8304 /dev/#{dev}")
        else
          exec("sgdisk -n#{nb}:0:0 -t#{nb}:#{code} /dev/#{dev}")
        end
      end

      def home(nb, code, dev)
        return if ! dev
        if DEFAULT_OPTIONS[:username]
          exec("sgdisk -n#{nb}:0:0 -t#{nb}:#{code} /dev/#{dev}")
        end
      end

      private

      def exec(cmd)
        if DEFAULT_OPTIONS[:encrypt]
          Getch::Command.new(cmd).run!
        else
          Getch::Command.new(cmd).run!
        end
      end
    end
  end
end
