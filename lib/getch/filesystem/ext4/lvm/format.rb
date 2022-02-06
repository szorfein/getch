# frozen_string_literal: true

require 'mkfs'

module Getch
  module FileSystem
    module Ext4
      module Lvm
        class Format
          def initialize
            x
          end

          def x
            Mkfs::Lvm.new(DEVS, OPTIONS)
          end
        end
      end
    end
  end
end
