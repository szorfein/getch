# frozen_string_literal: true

require 'nito'
require 'fstab'
require 'dracut'

module Getch
  module FileSystem
    module Ext4
      module Hybrid
        class Config
          include NiTo

          def initialize
            gen_uuid
            @devs = { esp: @dev_esp, boot: @dev_boot, root: @dev_root, home: @dev_home }
            crypttab
            x
          end

          protected

          def x
            Fstab::Hybrid.new(@devs, OPTIONS).generate
            Dracut::Hybrid.new(@devs, OPTIONS).generate
            grub
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
