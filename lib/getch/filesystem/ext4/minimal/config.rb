# frozen_string_literal: true

require 'fstab'
require 'dracut'

module Getch
  module FileSystem
    module Ext4
      module Minimal
        class Config
          def initialize
            @devs = {
              esp: @dev_esp, swap: @dev_swap, root: @dev_root, home: @dev_home
            }
            x
          end

          private

          def x
            Fstab::Minimal.new(@devs, OPTIONS).generate
            Dracut::Minimal.new(@devs, OPTIONS).generate
          end
        end
      end
    end
  end
end
