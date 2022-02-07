# frozen_string_literal: true

require 'mountfs'

module Getch
  module FileSystem
    module Ext4
      module Hybrid
        class Mount
          def initialize
            x
          end

          def x
            MountFs::Hybrid.new(DEVS, OPTIONS)
          end
        end
      end
    end
  end
end
