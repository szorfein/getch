# frozen_string_literal: true

require 'fstab'
require 'dracut'

module Getch
  module FileSystem
    module Zfs
      module Minimal
        class Config
          def initialize
            x
          end

          private

          def x
            Fstab::Zfs.new(DEVS, OPTIONS).generate
            Dracut::Zfs.new(DEVS, OPTIONS).generate
          end
        end
      end
    end
  end
end
