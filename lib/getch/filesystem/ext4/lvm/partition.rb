# frozen_string_literal: true

require 'sgdisk'
require 'lvm2'

module Getch
  module FileSystem
    module Ext4
      module Lvm
        class Partition
          def initialize
            x
          end

          private

          # Follow https://wiki.archlinux.org/index.php/Partitioning
          # 1 - Efi or GPT
          # 2 - Root
          def x
            Sgdisk::Lvm.new(DEVS)
            Lvm2::Root.new(DEVS, OPTIONS).x
          end
        end
      end
    end
  end
end
