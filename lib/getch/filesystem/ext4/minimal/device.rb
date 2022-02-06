# frozen_string_literal: true

require 'devs'

module Getch
  module FileSystem
    module Ext4
      module Minimal
        class Device
          def initialize
            @args = { start: true, swap: true, root: true }
            x
          end

          def x
            Devs::Settings.new(@args, OPTIONS)
          end
        end
      end
    end
  end
end
