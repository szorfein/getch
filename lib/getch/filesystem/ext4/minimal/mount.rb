# frozen_string_literal: true

require 'mountfs'

module Getch
  module FileSystem
    module Ext4
      module Minimal
        class Mount
          def initialize
            x
          end

          def x
            MountFs::Minimal.new(DEVS, OPTIONS)
          end
        end
      end
    end
  end
end
