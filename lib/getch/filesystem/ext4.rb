# frozen_string_literal: true

module Getch
  module FileSystem
    module Ext4
      def self.end
        puts '+ To enter in your system: chroot /mnt/getch /bin/bash'
        puts '+ Reboot with: shutdown -r now'
      end
    end
  end
end

require_relative 'ext4/minimal'
require_relative 'ext4/encrypt'
require_relative 'ext4/lvm'
require_relative 'ext4/hybrid'
