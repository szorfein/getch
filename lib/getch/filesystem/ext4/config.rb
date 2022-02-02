# frozen_string_literal: true

require 'fstab'
require 'dracut'

module Getch
  module FileSystem
    module Ext4
      class Config < Getch::FileSystem::Ext4::Device
        def initialize
          super
          @devs = {
            esp: @dev_esp, swap: @dev_swap, root: @dev_root, home: @dev_home
          }
          x
        end

        protected

        def x
          fstab
          cmdline
        end

        private

        def fstab
          Fstab::Minimal.new(@devs, OPTIONS).generate
        end

        def cmdline
          Dracut::Minimal.new(@devs, OPTIONS).generate
        end
      end
    end
  end
end
