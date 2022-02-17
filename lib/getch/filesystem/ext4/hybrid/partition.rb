# frozen_string_literal: true

require 'sgdisk'
require 'cryptsetup'
require 'lvm2'

module Getch
  module FileSystem
    module Ext4
      module Hybrid
        class Partition
          def initialize
            x
          end

          private

          def x
            Sgdisk::Encrypt.new(DEVS)
            CryptSetup.new(DEVS, OPTIONS).format
            Lvm2::Hybrid.new(DEVS, OPTIONS).x
          end
        end
      end
    end
  end
end
