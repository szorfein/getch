# frozen_string_literal: true

require 'nito'

module Getch
  module FileSystem
    class Mount
      include NiTo

      def initialize
        @root_dir = MOUNTPOINT
        @boot_dir = "#{@root_dir}/boot"
        @boot_efi_dir = "#{@root_dir}/efi"
        @home_dir = "#{@root_dir}/home"
        @state = Getch::States.new
        @log = Getch::Log.new
      end

      def swap(dev)
        return unless dev

        return if grep? '/proc/swaps', "/dev/#{@dev}"

        exec("swapon #{dev}")
      end

      def root(dev)
        return unless dev

        mkdir @root_dir
        exec("mount #{dev} #{@root_dir}")
      end

      def esp(dev)
        return unless dev

        mkdir @boot_efi_dir
        exec("mount #{dev} #{@boot_efi_dir}")
      end

      def boot(dev)
        return unless dev

        mkdir @boot_dir
        exec("mount #{dev} #{@boot_dir}")
      end

      def home(dev)
        return unless dev

        mkdir @home_dir
        exec("mount #{dev} #{@home_dir}")
      end

      private

      def exec(*cmd)
        Getch::Command.new(cmd).run!
      end
    end
  end
end
