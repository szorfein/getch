# frozen_string_literal: true

require 'fstab'
require 'dracut'

module Getch
  module FileSystem
    module Ext4
      module Minimal
        class Config
          def initialize
            x
          end

          private

          def x
            Fstab::Minimal.new(DEVS, OPTIONS).generate
            Dracut::Minimal.new(DEVS, OPTIONS).generate
          end
        end
      end
    end
  end
end
