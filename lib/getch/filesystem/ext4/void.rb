# frozen_string_literal: true

module Getch
  module FileSystem
    module Ext4
      class Void < Device

        attr_reader :boot_disk

        def finish
          puts '+ Enter in your system: chroot /mnt /bin/bash'
          puts '+ Reboot with: shutdown -r now'
        end
      end
    end
  end
end
