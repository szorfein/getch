# frozen_string_literal: true

require 'sgdisk'

module Getch
  module FileSystem
    module Ext4
      module Minimal
        class Partition
          def initialize
            x
          end

          private

          # Follow https://wiki.archlinux.org/index.php/Partitioning
          # 1 - /efi of GPT
          # 2 - Swap
          # 3 - /
          # 4 - /home if --separate-home DISK is used
          def x
            Sgdisk::Ext4.new(DEVS)
          end
        end
      end
    end
  end
end
