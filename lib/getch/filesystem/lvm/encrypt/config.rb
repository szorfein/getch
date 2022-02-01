# frozen_string_literal: true

require 'fstab'
require 'nito'

module Getch
  module FileSystem
    module Lvm
      module Encrypt
        class Config < Getch::FileSystem::Lvm::Encrypt::Device
          include NiTo

          def initialize
            super
            gen_uuid
            crypttab
          end

          def fstab
            devs = { esp: @dev_esp, boot: @dev_boot, root: @dev_root, home: @dev_home }
            Fstab::Hybrid.new(devs, OPTIONS).generate
          end

          def systemd_boot
          end

          def crypttab
            datas = [
              "cryptswap #{@lv_swap} /dev/urandom swap,cipher=aes-xts-plain64:sha256,size=512"
            ]
            File.write("#{MOUNTPOINT}/etc/crypttab", datas.join("\n"))
          end

          def grub
            return unless File.exist? "#{MOUNTPOINT}/etc/default/grub"

            file = "#{MOUNTPOINT}/etc/default/grub"
            echo_a file, 'GRUB_ENABLE_CRYPTODISK=y'
          end
        end
      end
    end
  end
end
