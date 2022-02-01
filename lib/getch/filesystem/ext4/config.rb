# frozen_string_literal: true

require 'fstab'

module Getch
  module FileSystem
    module Ext4
      class Config < Getch::FileSystem::Ext4::Device
        def initialize
          super
          x
        end

        protected

        def x
          fstab
          gen_uuid
          cmdline
        end

        private

        def fstab
          devs = {
            esp: @dev_esp, swap: @dev_swap, root: @dev_root, home: @dev_home
          }
          Fstab::Minimal.new(devs, OPTIONS).generate
        end

        def cmdline
          conf = "#{MOUNTPOINT}/etc/dracut.conf.d/cmdline.conf"
          line = "resume=PARTUUID=#{@partuuid_swap} root=PARTUUID=#{@partuuid_root}"
          File.write conf, "kernel_cmdline=\"#{line}\"\n"
        end

        private

        def gen_uuid
          @partuuid_root = Helpers.partuuid(@dev_root)
          @partuuid_swap = Helpers.partuuid(@dev_swap)
        end
      end
    end
  end
end
