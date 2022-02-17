# frozen_string_literal: true

require 'sgdisk'
require 'cryptsetup'

module Getch
  module FileSystem
    module Ext4
      module Encrypt
        class Partition
          def initialize
            x
          end

          private

          def x
            Sgdisk::Encrypt.new(DEVS)
            CryptSetup.new(DEVS, OPTIONS).format
          end
        end
      end
    end
  end
end
