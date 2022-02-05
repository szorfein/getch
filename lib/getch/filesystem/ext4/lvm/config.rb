# frozen_string_literal: true

require 'fstab'
require 'dracut'

module Getch
  module FileSystem
    module Ext4
      module Lvm
        class Config
          def initialize
            @devs = {
              esp: @dev_esp, root: @dev_root
            }
            x
          end

          private

          def x
            Fstab::Lvm.new(@devs, OPTIONS).generate
            Dracut::Lvm.new(@devs, OPTIONS).generate
          end
        end
      end
    end
  end
end
