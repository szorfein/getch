# frozen_string_literal: true

require 'fstab'
require 'dracut'

module Getch
  module FileSystem
    module Ext4
      module Lvm
        class Config
          def initialize
            x
          end

          private

          def x
            Fstab::Lvm.new(DEVS, OPTIONS).generate
            Dracut::Lvm.new(DEVS, OPTIONS).generate
          end
        end
      end
    end
  end
end
