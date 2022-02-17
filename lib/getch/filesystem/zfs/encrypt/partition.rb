# frozen_string_literal: true

require 'sgdisk'

module Getch
  module FileSystem
    module Zfs
      module Encrypt
        class Partition
          def initialize
            x
          end

          private

          def x
            Sgdisk::Zfs.new(DEVS)
          end
        end
      end
    end
  end
end
