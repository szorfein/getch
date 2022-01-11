require 'fileutils'

module Getch
  module FileSystem
    class Mount
      def initialize
        @root_dir = MOUNTPOINT
        @boot_dir = "#{@root_dir}/boot"
        @boot_efi_dir = "#{@root_dir}/efi"
        @home_dir = "#{@root_dir}/home"
        @state = Getch::States.new()
        @log = Getch::Log.new
      end

      def swap(dev)
        return unless dev

        if Helpers.grep?('/proc/swaps', /^\/dev/)
          exec("swapoff #{dev}")
        end

        exec("swapon #{dev}")
      end

      def root(dev)
        return unless dev

        Helpers.mkdir(@root_dir)
        exec("mount #{dev} #{@root_dir}")
      end

      def esp(dev)
        return unless dev

        Helpers.mkdir(@boot_efi_dir)
        exec("mount #{dev} #{@boot_efi_dir}")
      end

      def boot(dev)
        return unless dev

        Helpers.mkdir(@boot_dir)
        exec("mount #{dev} #{@boot_dir}")
      end

      def home(dev)
        return unless dev

        Helpers.mkdir(@home_dir)
        exec("mount #{dev} #{@home_dir}")
      end

      private

      def exec(cmd)
        @log.info("==> #{cmd}")
        Helpers.sys(cmd)
      end
    end
  end
end
